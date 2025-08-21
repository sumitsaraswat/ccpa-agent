-- CCPA Agent - Executive Reporting Examples
-- Management dashboards and compliance metrics

-- ============================================================================
-- Setup
-- ============================================================================
USE CATALOG your_catalog;
USE SCHEMA compliance;

-- ============================================================================
-- Executive Summary Dashboard
-- ============================================================================

-- High-level compliance metrics by category
SELECT 
  ccpa_category,
  COUNT(*) as total_tables,
  SUM(CASE WHEN consumer_right_to_delete THEN 1 ELSE 0 END) as deletable_tables,
  SUM(CASE WHEN consumer_right_to_opt_out THEN 1 ELSE 0 END) as opt_out_required,
  SUM(CASE WHEN sensitive_personal_info THEN 1 ELSE 0 END) as sensitive_tables,
  COUNT(CASE WHEN implementation_gap != 'Implementation appears complete' THEN 1 END) as tables_with_gaps,
  ROUND(
    (COUNT(CASE WHEN implementation_gap = 'Implementation appears complete' THEN 1 END) * 100.0) / COUNT(*), 
    2
  ) as compliance_percentage
FROM ccpa_data_inventory()
GROUP BY ccpa_category
ORDER BY sensitive_tables DESC, total_tables DESC;

-- ============================================================================
-- Risk Assessment Report
-- ============================================================================

-- High-risk tables requiring immediate attention
SELECT 
  'HIGH PRIORITY - Sensitive PII' as priority_level,
  table_location,
  personal_info_elements,
  implementation_gap,
  retention_period
FROM ccpa_data_inventory()
WHERE sensitive_personal_info = TRUE
  AND implementation_gap != 'Implementation appears complete'

UNION ALL

SELECT 
  'MEDIUM PRIORITY - Opt-out Required' as priority_level,
  table_location,
  personal_info_elements,
  implementation_gap,
  retention_period
FROM ccpa_data_inventory()
WHERE consumer_right_to_opt_out = TRUE
  AND implementation_gap LIKE '%opt-out%'

ORDER BY priority_level, table_location;

-- ============================================================================
-- Data Categories Overview
-- ============================================================================

-- Summary of personal information categories
SELECT 
  ccpa_category,
  COLLECT_SET(FLATTEN(personal_info_elements)) as unique_pii_types,
  COUNT(DISTINCT table_location) as affected_tables,
  ROUND(AVG(CASE WHEN sensitive_personal_info THEN 1.0 ELSE 0.0 END) * 100, 1) as pct_sensitive
FROM ccpa_data_inventory()
GROUP BY ccpa_category
ORDER BY affected_tables DESC;

-- ============================================================================
-- Implementation Gap Analysis
-- ============================================================================

-- Breakdown of implementation gaps by priority
WITH gap_priority AS (
  SELECT 
    implementation_gap,
    CASE 
      WHEN implementation_gap LIKE '%opt-out%' AND sensitive_personal_info THEN 'CRITICAL'
      WHEN implementation_gap LIKE '%security%' THEN 'HIGH'
      WHEN implementation_gap LIKE '%retention%' THEN 'MEDIUM'
      WHEN implementation_gap = 'Implementation appears complete' THEN 'COMPLETE'
      ELSE 'REVIEW NEEDED'
    END as priority_level,
    table_location,
    sensitive_personal_info
  FROM ccpa_data_inventory()
)
SELECT 
  priority_level,
  COUNT(*) as table_count,
  COUNT(CASE WHEN sensitive_personal_info THEN 1 END) as sensitive_count,
  COLLECT_SET(implementation_gap) as gap_types
FROM gap_priority
GROUP BY priority_level
ORDER BY 
  CASE priority_level 
    WHEN 'CRITICAL' THEN 1 
    WHEN 'HIGH' THEN 2 
    WHEN 'MEDIUM' THEN 3 
    WHEN 'REVIEW NEEDED' THEN 4 
    WHEN 'COMPLETE' THEN 5 
  END;

-- ============================================================================
-- Consumer Request Volume Estimation
-- ============================================================================

-- Estimate effort for different types of consumer requests
SELECT 
  'Deletion Request' as request_type,
  COUNT(*) as affected_tables,
  SUM(CASE WHEN deletion_complexity = 'High' THEN 1 ELSE 0 END) as high_complexity,
  SUM(CASE WHEN deletion_complexity = 'Medium' THEN 1 ELSE 0 END) as medium_complexity,
  SUM(CASE WHEN deletion_complexity = 'Low' THEN 1 ELSE 0 END) as low_complexity,
  ROUND(AVG(estimated_effort_hours), 1) as avg_effort_hours,
  ROUND(SUM(estimated_effort_hours), 1) as total_effort_hours
FROM ccpa_consumer_request_impact('sample@email.com', 'email', 'delete')

UNION ALL

SELECT 
  'Opt-out Request' as request_type,
  COUNT(*) as affected_tables,
  0 as high_complexity,
  0 as medium_complexity,
  0 as low_complexity,
  ROUND(AVG(estimated_effort_hours), 1) as avg_effort_hours,
  ROUND(SUM(estimated_effort_hours), 1) as total_effort_hours
FROM ccpa_consumer_request_impact('sample@email.com', 'email', 'opt_out')
WHERE consumer_rights_applicable LIKE '%APPLICABLE%';
