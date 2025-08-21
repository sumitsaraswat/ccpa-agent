-- CCPA Agent - Basic Usage Examples
-- Replace 'your_catalog' with your actual catalog name

-- ============================================================================
-- Setup
-- ============================================================================
USE CATALOG your_catalog;
USE SCHEMA compliance;

-- ============================================================================
-- Example 1: Complete PII Inventory
-- ============================================================================
-- Get comprehensive PII inventory across all tables
SELECT 
    table_location,
    ccpa_category,
    personal_info_elements,
    sensitive_personal_info,
    detection_method,
    implementation_gap
FROM ccpa_data_inventory()
ORDER BY sensitive_personal_info DESC, ccpa_category;

-- ============================================================================
-- Example 2: Focus on High-Risk Sensitive Data
-- ============================================================================
-- Focus on sensitive PII requiring enhanced security
SELECT 
    table_location,
    personal_info_elements,
    business_purpose,
    retention_period,
    implementation_gap
FROM ccpa_data_inventory()
WHERE sensitive_personal_info = TRUE
ORDER BY table_location;

-- ============================================================================
-- Example 3: Consumer Deletion Request Analysis
-- ============================================================================
-- Analyze deletion request impact for a specific consumer
SELECT 
    affected_table,
    deletion_complexity,
    estimated_effort_hours,
    legal_hold_status,
    business_impact,
    compliance_deadline
FROM ccpa_consumer_request_impact('john.doe@example.com', 'email', 'delete')
ORDER BY deletion_complexity DESC, estimated_effort_hours DESC;

-- ============================================================================
-- Example 4: Opt-Out Request Analysis
-- ============================================================================
-- Analyze opt-out request to stop data sale/sharing
SELECT 
    affected_table,
    ccpa_category,
    consumer_rights_applicable,
    business_impact,
    dependent_systems
FROM ccpa_consumer_request_impact('user@company.com', 'email', 'opt_out')
WHERE consumer_rights_applicable LIKE '%APPLICABLE%'
ORDER BY business_impact DESC;

-- ============================================================================
-- Example 5: Right to Know Request Analysis
-- ============================================================================
-- Analyze what data is collected about a consumer
SELECT 
    affected_table,
    ccpa_category,
    estimated_record_count,
    business_impact,
    consumer_rights_applicable
FROM ccpa_consumer_request_impact('customer@email.com', 'email', 'know')
ORDER BY estimated_record_count DESC;

-- ============================================================================
-- Example 6: Tables Requiring Immediate Attention
-- ============================================================================
-- Find tables with implementation gaps
SELECT 
    table_location,
    ccpa_category,
    implementation_gap,
    sensitive_personal_info
FROM ccpa_data_inventory()
WHERE implementation_gap != 'Implementation appears complete'
ORDER BY sensitive_personal_info DESC, ccpa_category;
