-- CCPA Agent - End-to-End Compliance Workflows
-- Complete workflows for common compliance scenarios

-- ============================================================================
-- Setup
-- ============================================================================
USE CATALOG your_catalog;
USE SCHEMA compliance;

-- ============================================================================
-- Workflow 1: New Consumer Deletion Request
-- ============================================================================

-- Step 1: Identify all affected tables and data
CREATE OR REPLACE TEMPORARY VIEW deletion_request_analysis AS
SELECT 
    affected_table,
    ccpa_category,
    estimated_record_count,
    deletion_complexity,
    legal_hold_status,
    business_impact,
    automated_deletion,
    manual_review_required,
    estimated_effort_hours,
    dependent_systems,
    compliance_deadline,
    consumer_rights_applicable,
    retention_override_reason
FROM ccpa_consumer_request_impact(
    'customer@example.com',  -- Replace with actual consumer identifier
    'email',                 -- Identifier type: email, phone, name, ssn, address
    'delete'                 -- Request type
);

-- Step 2: Generate work orders by complexity
SELECT 
    'IMMEDIATE ACTION REQUIRED' as priority,
    affected_table,
    deletion_complexity,
    legal_hold_status,
    estimated_effort_hours,
    'Manual legal review required' as action_needed
FROM deletion_request_analysis
WHERE legal_hold_status != 'No legal hold identified'
   OR deletion_complexity = 'High'

UNION ALL

SELECT 
    'AUTOMATED PROCESSING' as priority,
    affected_table,
    deletion_complexity,
    legal_hold_status,
    estimated_effort_hours,
    'Can be processed automatically' as action_needed
FROM deletion_request_analysis
WHERE automated_deletion = TRUE
  AND legal_hold_status = 'No legal hold identified'

UNION ALL

SELECT 
    'MANUAL REVIEW REQUIRED' as priority,
    affected_table,
    deletion_complexity,
    legal_hold_status,
    estimated_effort_hours,
    'Requires manual assessment' as action_needed
FROM deletion_request_analysis
WHERE manual_review_required = TRUE
  AND legal_hold_status = 'No legal hold identified'
  AND deletion_complexity != 'High'

ORDER BY 
    CASE priority 
        WHEN 'IMMEDIATE ACTION REQUIRED' THEN 1
        WHEN 'MANUAL REVIEW REQUIRED' THEN 2
        WHEN 'AUTOMATED PROCESSING' THEN 3
    END,
    estimated_effort_hours DESC;

-- ============================================================================
-- Workflow 2: Quarterly Compliance Review
-- ============================================================================

-- Generate comprehensive compliance report
WITH compliance_metrics AS (
  SELECT 
    table_location,
    ccpa_category,
    sensitive_personal_info,
    implementation_gap,
    consumer_right_to_delete,
    consumer_right_to_opt_out,
    CASE 
      WHEN implementation_gap = 'Implementation appears complete' THEN 'COMPLIANT'
      WHEN implementation_gap LIKE '%security%' THEN 'SECURITY_GAP'
      WHEN implementation_gap LIKE '%opt-out%' THEN 'OPTOUT_GAP'
      WHEN implementation_gap LIKE '%retention%' THEN 'RETENTION_GAP'
      ELSE 'OTHER_GAP'
    END as gap_category
  FROM ccpa_data_inventory()
)
SELECT 
  'Q' || QUARTER(CURRENT_DATE()) || ' ' || YEAR(CURRENT_DATE()) as report_period,
  gap_category,
  COUNT(*) as table_count,
  COUNT(CASE WHEN sensitive_personal_info THEN 1 END) as sensitive_tables,
  ROUND((COUNT(*) * 100.0) / SUM(COUNT(*)) OVER (), 2) as percentage_of_total
FROM compliance_metrics
GROUP BY gap_category
ORDER BY table_count DESC;

-- ============================================================================
-- Workflow 3: Data Subject Access Request (Right to Know)
-- ============================================================================

-- Complete data disclosure for consumer
CREATE OR REPLACE TEMPORARY VIEW data_access_request AS
SELECT 
    affected_table,
    ccpa_category,
    estimated_record_count,
    business_impact as business_purpose,
    consumer_rights_applicable,
    compliance_deadline
FROM ccpa_consumer_request_impact(
    'consumer@example.com',  -- Replace with actual consumer identifier
    'email',                 -- Identifier type
    'know'                   -- Request type: Right to Know
);

-- Generate consumer disclosure report
SELECT 
    'CCPA Data Disclosure Report' as report_type,
    CURRENT_DATE() as request_date,
    COUNT(*) as total_data_sources,
    SUM(estimated_record_count) as total_records,
    COLLECT_SET(ccpa_category) as data_categories,
    MAX(compliance_deadline) as response_deadline
FROM data_access_request
WHERE consumer_rights_applicable LIKE '%APPLICABLE%';

-- Detailed breakdown by category
SELECT 
    ccpa_category,
    COUNT(*) as data_sources,
    SUM(estimated_record_count) as record_count,
    COLLECT_SET(affected_table) as affected_systems
FROM data_access_request
WHERE consumer_rights_applicable LIKE '%APPLICABLE%'
GROUP BY ccpa_category
ORDER BY record_count DESC;

-- ============================================================================
-- Workflow 4: Opt-Out Request Processing
-- ============================================================================

-- Identify systems requiring opt-out configuration
CREATE OR REPLACE TEMPORARY VIEW opt_out_analysis AS
SELECT 
    affected_table,
    ccpa_category,
    business_impact,
    dependent_systems,
    consumer_rights_applicable,
    compliance_deadline
FROM ccpa_consumer_request_impact(
    'consumer@example.com',  -- Replace with actual consumer identifier
    'email',                 -- Identifier type
    'opt_out'               -- Request type: Opt-out of sale/sharing
)
WHERE consumer_rights_applicable LIKE '%APPLICABLE%';

-- Generate system configuration checklist
SELECT 
    EXPLODE(dependent_systems) as system_name,
    COUNT(*) as affected_tables,
    COLLECT_SET(ccpa_category) as data_categories,
    'Configure opt-out mechanism' as required_action,
    MAX(compliance_deadline) as deadline
FROM opt_out_analysis
GROUP BY system_name
ORDER BY affected_tables DESC;

-- ============================================================================
-- Workflow 5: Implementation Gap Remediation
-- ============================================================================

-- Prioritized remediation plan
WITH remediation_priorities AS (
  SELECT 
    table_location,
    implementation_gap,
    sensitive_personal_info,
    ccpa_category,
    CASE 
      WHEN implementation_gap LIKE '%opt-out%' AND ccpa_category IN ('Identifiers', 'Internet or Network Activity') THEN 1
      WHEN implementation_gap LIKE '%security%' AND sensitive_personal_info THEN 2
      WHEN implementation_gap LIKE '%retention%' THEN 3
      WHEN implementation_gap LIKE '%backup%' THEN 4
      ELSE 5
    END as priority_order,
    CASE 
      WHEN implementation_gap LIKE '%opt-out%' THEN 'Implement consumer opt-out mechanism'
      WHEN implementation_gap LIKE '%security%' THEN 'Enhance security controls and access restrictions'
      WHEN implementation_gap LIKE '%retention%' THEN 'Define and implement data retention policy'
      WHEN implementation_gap LIKE '%backup%' THEN 'Establish backup deletion procedures'
      ELSE 'Review implementation requirements'
    END as remediation_action
  FROM ccpa_data_inventory()
  WHERE implementation_gap != 'Implementation appears complete'
)
SELECT 
  priority_order,
  remediation_action,
  COUNT(*) as affected_tables,
  COUNT(CASE WHEN sensitive_personal_info THEN 1 END) as sensitive_tables,
  COLLECT_SET(ccpa_category) as affected_categories
FROM remediation_priorities
GROUP BY priority_order, remediation_action
ORDER BY priority_order, affected_tables DESC;
