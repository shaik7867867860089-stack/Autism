-- ============================================================
-- 1. MASTER LOCATION TABLES
-- ============================================================

CREATE TABLE states (
    state_id SERIAL PRIMARY KEY,
    state_name VARCHAR(150) NOT NULL
);

CREATE TABLE districts (
    district_id SERIAL PRIMARY KEY,
    state_id INT REFERENCES states(state_id),
    district_name VARCHAR(150) NOT NULL
);

CREATE TABLE mandals (
    mandal_id SERIAL PRIMARY KEY,
    district_id INT REFERENCES districts(district_id),
    mandal_name VARCHAR(150) NOT NULL
);

CREATE TABLE anganwadi_centers (
    center_id SERIAL PRIMARY KEY,
    mandal_id INT REFERENCES mandals(mandal_id),
    center_code VARCHAR(50) UNIQUE,
    center_name VARCHAR(150)
);

-- ============================================================
-- 2. CHILD MASTER TABLE
-- ============================================================

CREATE TABLE children (
    child_id SERIAL PRIMARY KEY,
    unique_child_code VARCHAR(100) UNIQUE NOT NULL,
    first_name VARCHAR(100),
    mother_name VARCHAR(100),
    dob DATE NOT NULL,
    gender VARCHAR(20),

    center_id INT REFERENCES anganwadi_centers(center_id),

    caregiver_name VARCHAR(150),
    caregiver_education VARCHAR(100),
    contact_number VARCHAR(20),

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(50) DEFAULT 'Active'
);

CREATE INDEX idx_children_center ON children(center_id);
CREATE INDEX idx_children_unique_code ON children(unique_child_code);

-- ============================================================
-- 3. ASSESSMENTS (LONGITUDINAL)
-- ============================================================

CREATE TABLE assessments (
    assessment_id SERIAL PRIMARY KEY,
    child_id INT REFERENCES children(child_id),

    assessment_cycle INT NOT NULL,
    assessment_date DATE NOT NULL,
    age_months INT NOT NULL,

    -- Developmental Scores
    gross_motor_dq FLOAT,
    fine_motor_dq FLOAT,
    language_dq FLOAT,
    cognitive_dq FLOAT,
    socio_emotional_dq FLOAT,
    composite_dq FLOAT,
    delayed_domains INT,

    -- Neuro Behavioral
    autism_screen_flag FLOAT,
    attention_score FLOAT,
    behavior_score FLOAT,

    -- Nutrition
    stunting BOOLEAN,
    wasting BOOLEAN,
    anemia BOOLEAN,
    nutrition_score INT,

    -- Environment
    stimulation_score INT,
    caregiver_engagement_score INT,
    language_exposure_score BOOLEAN,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_assessment_child ON assessments(child_id);
CREATE INDEX idx_assessment_date ON assessments(assessment_date);

-- ============================================================
-- 4. ENGINEERED FEATURES
-- ============================================================

CREATE TABLE engineered_features (
    feature_id SERIAL PRIMARY KEY,
    assessment_id INT REFERENCES assessments(assessment_id),

    developmental_severity_index FLOAT,
    neuro_risk_index FLOAT,
    nutrition_risk_index FLOAT,
    environment_risk_index FLOAT,

    dq_delta FLOAT,
    delay_delta INT,
    nutrition_delta FLOAT,
    behavior_delta FLOAT,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- 5. MODEL PREDICTIONS
-- ============================================================

CREATE TABLE model_predictions (
    prediction_id SERIAL PRIMARY KEY,
    assessment_id INT REFERENCES assessments(assessment_id),

    model_version VARCHAR(50),

    -- Model A Output
    low_probability FLOAT,
    medium_probability FLOAT,
    high_probability FLOAT,
    critical_probability FLOAT,
    predicted_risk_class VARCHAR(50),

    -- Model B Output
    escalation_probability FLOAT,
    predicted_escalation BOOLEAN,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_prediction_assessment ON model_predictions(assessment_id);

-- ============================================================
-- 6. SHAP EXPLANATIONS
-- ============================================================

CREATE TABLE shap_explanations (
    shap_id SERIAL PRIMARY KEY,
    prediction_id INT REFERENCES model_predictions(prediction_id),

    feature_name VARCHAR(150),
    contribution_value FLOAT
);

-- ============================================================
-- 7. REFERRALS
-- ============================================================

CREATE TABLE referrals (
    referral_id SERIAL PRIMARY KEY,
    assessment_id INT REFERENCES assessments(assessment_id),

    risk_level_at_referral VARCHAR(50),
    referral_generated BOOLEAN DEFAULT FALSE,
    referral_date DATE,

    referred_to VARCHAR(200),
    referral_completed BOOLEAN DEFAULT FALSE,
    completion_date DATE,

    status VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_referral_status ON referrals(status);

-- ============================================================
-- 8. INTERVENTIONS
-- ============================================================

CREATE TABLE interventions (
    intervention_id SERIAL PRIMARY KEY,
    child_id INT REFERENCES children(child_id),

    intervention_type VARCHAR(200),
    start_date DATE,
    end_date DATE,

    sessions_completed INT,
    compliance_percentage FLOAT,

    improvement_status VARCHAR(100),
    delay_reduction_months FLOAT,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- 9. USERS (UPDATED WITH PARENT ROLE)
-- ============================================================

CREATE TABLE users (
    user_id SERIAL PRIMARY KEY,
    full_name VARCHAR(150),
    email VARCHAR(150) UNIQUE,
    password_hash VARCHAR(255),

    role VARCHAR(100), 
    -- Possible Values:
    -- anganwadi_worker
    -- supervisor
    -- district_officer
    -- state_admin
    -- system_admin
    -- parent

    state_id INT REFERENCES states(state_id),
    district_id INT REFERENCES districts(district_id),
    mandal_id INT REFERENCES mandals(mandal_id),
    center_id INT REFERENCES anganwadi_centers(center_id),

    status VARCHAR(50) DEFAULT 'Active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_users_role ON users(role);

-- ============================================================
-- 10. PARENT_CHILD_MAPPING (NEW AS PER ER DIAGRAM)
-- ============================================================

CREATE TABLE parent_child_mapping (
    mapping_id SERIAL PRIMARY KEY,
    user_id INT REFERENCES users(user_id),
    child_id INT REFERENCES children(child_id),

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    UNIQUE(user_id, child_id)
);

-- ============================================================
-- 11. AUDIT LOGS
-- ============================================================

CREATE TABLE audit_logs (
    log_id SERIAL PRIMARY KEY,
    user_id INT REFERENCES users(user_id),

    action VARCHAR(200),
    entity_type VARCHAR(100),
    entity_id INT,

    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ip_address VARCHAR(50)
);

-- ============================================================
-- 12. DISTRICT SUMMARY (AGGREGATED ANALYTICS)
-- ============================================================

CREATE TABLE district_summary (
    summary_id SERIAL PRIMARY KEY,
    district_id INT REFERENCES districts(district_id),
    report_month DATE,

    total_children INT,
    low_risk INT,
    medium_risk INT,
    high_risk INT,
    critical_risk INT,

    referral_completion_rate FLOAT,
    risk_escalation_rate FLOAT,
    improvement_rate FLOAT
);

CREATE INDEX idx_district_summary 
ON district_summary(district_id, report_month);

-- ============================================================
-- END OF FINAL SCHEMA
-- ============================================================
