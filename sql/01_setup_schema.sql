-- CCPA Agent Setup Script
-- Creates the compliance schema and initial configurations
-- Author: Sumit Saraswat
-- Version: 1.0.0

-- ============================================================================
-- STEP 1: Update this with your catalog name
-- ============================================================================
USE CATALOG your_catalog_name; -- CHANGE THIS TO YOUR ACTUAL CATALOG NAME

-- ============================================================================
-- STEP 2: Create compliance schema for CCPA functions
-- ============================================================================
CREATE SCHEMA IF NOT EXISTS compliance
COMMENT 'CCPA compliance automation functions and views for automated PII discovery and consumer request management';

USE SCHEMA compliance;

-- ============================================================================
-- STEP 3: Verify setup
-- ============================================================================
SHOW SCHEMAS IN your_catalog_name;

-- ============================================================================
-- STEP 4: Grant permissions (uncomment and adjust as needed)
-- ============================================================================
-- Grant permissions to your compliance team
-- GRANT SELECT ON SCHEMA compliance TO `your_compliance_team`;
-- GRANT EXECUTE ON SCHEMA compliance TO `your_compliance_team`;
-- GRANT CREATE ON SCHEMA compliance TO `your_data_engineers`;

-- ============================================================================
-- Setup Complete
-- ============================================================================
SELECT 
  'CCPA Agent schema setup complete!' as status,
  CURRENT_CATALOG() as catalog_name,
  'compliance' as schema_name,
  CURRENT_TIMESTAMP() as setup_time;
