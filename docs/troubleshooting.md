# Troubleshooting Guide

## Common Issues and Solutions

### Installation Issues

#### Issue: "Catalog not found" Error
```
Error: Catalog 'your_catalog' not found
```

**Solution:**
```sql
-- Check available catalogs
SHOW CATALOGS;

-- Verify you have access to the correct catalog
USE CATALOG correct_catalog_name;
```

#### Issue: Permission Denied on information_schema
```
Error: Permission denied: User does not have SELECT privilege on information_schema.columns
```

**Solution:**
```sql
-- Contact your Databricks admin to grant permissions
-- Required permissions:
-- GRANT SELECT ON information_schema.columns TO `your_user`;
-- GRANT SELECT ON information_schema.tables TO `your_user`;
-- GRANT SELECT ON system.information_schema.column_tags TO `your_user`;
```

#### Issue: Functions Created but Return No Data
```sql
-- Check if your catalog actually contains tables with PII
SELECT 
  table_catalog,
  table_schema,
  table_name,
  column_name
FROM information_schema.columns 
WHERE table_catalog = 'your_catalog'
  AND (
    LOWER(column_name) LIKE '%email%' OR
    LOWER(column_name) LIKE '%phone%' OR
    LOWER(column_name) LIKE '%name%'
  )
LIMIT 10;
```

### Runtime Issues

#### Issue: Function Execution Timeout
```
Error: Query timeout after 600 seconds
```

**Solutions:**
1. **Limit scope for testing:**
```sql
-- Test with specific schema only
SELECT * FROM ccpa_data_inventory() 
WHERE table_location LIKE 'your_catalog.specific_schema.%'
LIMIT 10;
```

2. **Check cluster resources:**
   - Ensure adequate cluster size
   - Consider using a larger cluster for initial inventory

#### Issue: Memory Issues with Large Catalogs
```
Error: Out of memory error during function execution
```

**Solutions:**
1. **Process by schema:**
```sql
-- Create temporary function for specific schema
CREATE OR REPLACE TEMPORARY VIEW schema_inventory AS
SELECT * FROM information_schema.columns 
WHERE table_catalog = 'your_catalog' 
  AND table_schema = 'specific_schema';
```

2. **Batch processing:**
```sql
-- Process tables in batches
SELECT * FROM ccpa_data_inventory() 
WHERE table_location LIKE 'your_catalog.schema1.%'
UNION ALL
SELECT * FROM ccpa_data_inventory() 
WHERE table_location LIKE 'your_catalog.schema2.%';
```

### Data Quality Issues

#### Issue: False Positive PII Detection
```
Column 'customer_id' detected as PII but contains only numeric IDs
```

**Solutions:**
1. **Use explicit tags:**
```sql
ALTER TABLE your_schema.your_table 
ALTER COLUMN customer_id 
SET TAGS ('pii_type' = 'none');
```

2. **Update column comments:**
```sql
ALTER TABLE your_schema.your_table 
ALTER COLUMN customer_id 
COMMENT 'Numeric customer identifier - not PII';
```

#### Issue: Missing PII Detection
```
Known PII columns not being detected
```

**Solutions:**
1. **Add column tags:**
```sql
ALTER TABLE your_schema.your_table 
ALTER COLUMN hidden_email_field 
SET TAGS ('pii_type' = 'email');
```

2. **Add descriptive comments:**
```sql
ALTER TABLE your_schema.your_table 
ALTER COLUMN data_field 
COMMENT 'Contains customer email addresses';
```

3. **Check naming patterns:**
```sql
-- Verify column names match detection patterns
SELECT column_name 
FROM information_schema.columns 
WHERE table_name = 'your_table'
  AND LOWER(column_name) NOT RLIKE '.*(email|phone|name|address).*';
```

### Performance Issues

#### Issue: Slow Query Performance
```
Query takes too long to execute on large catalogs
```

**Solutions:**
1. **Use table filtering:**
```sql
-- Focus on specific table patterns
SELECT * FROM ccpa_data_inventory() 
WHERE table_location LIKE '%customer%' 
   OR table_location LIKE '%user%'
   OR table_location LIKE '%profile%';
```

2. **Create materialized views:**
```sql
-- Cache results for faster access
CREATE OR REPLACE VIEW cached_pii_inventory AS
SELECT * FROM ccpa_data_inventory();

-- Refresh periodically
REFRESH TABLE cached_pii_inventory;
```

3. **Optimize cluster configuration:**
   - Use multi-node clusters for large catalogs
   - Enable auto-scaling
   - Consider photon acceleration

### Consumer Request Issues

#### Issue: No Data Returned for Consumer Request
```sql
-- Check if identifier exists in your data
SELECT 
  table_location,
  personal_info_elements
FROM ccpa_data_inventory()
WHERE ARRAYS_OVERLAP(personal_info_elements, ARRAY('email'));
```

#### Issue: Incorrect Effort Estimation
```
Effort hours seem too high/low for our organization
```

**Solution: Customize effort calculations:**
```sql
-- Update effort estimation logic in consumer_request_impact function
CASE 
  WHEN complexity = 'High' AND legal_hold != 'No legal hold identified' THEN 8.0  -- Reduced from 12.0
  WHEN complexity = 'High' THEN 6.0  -- Reduced from 8.0
  -- Adjust based on your organization's capabilities
END
```

### Integration Issues

#### Issue: Column Tags Not Detected
```sql
-- Verify tag schema and permissions
SELECT 
  catalog_name,
  schema_name,
  table_name,
  column_name,
  tag_name,
  tag_value
FROM system.information_schema.column_tags
WHERE catalog_name = 'your_catalog'
LIMIT 5;
```

#### Issue: System Dependencies Not Accurate
```
Dependent systems list doesn't match our architecture
```

**Solution: Update system mapping:**
```sql
-- Customize dependent systems logic
CASE 
  WHEN table_location RLIKE '.*customer.*|.*user.*' 
    THEN ARRAY('Your CRM', 'Your Customer Portal', 'Your Database')
  WHEN table_location RLIKE '.*financial.*|.*billing.*' 
    THEN ARRAY('Your ERP', 'Your Billing System', 'Your Payment Gateway')
  -- Add your specific system mappings
END
```

## Debugging Techniques

### Enable Detailed Logging
```sql
-- Add debug output to understand detection logic
SELECT 
  table_catalog,
  table_schema,
  table_name,
  column_name,
  COALESCE(comment, 'No comment') as column_comment,
  COALESCE(ct.tag_value, 'No tags') as column_tags,
  CASE 
    WHEN UPPER(COALESCE(ct.tag_value, '')) RLIKE '.*(EMAIL|PHONE|NAME).*' THEN 'Detected via tags'
    WHEN UPPER(COALESCE(c.comment, '')) RLIKE '.*(EMAIL|PHONE|NAME).*' THEN 'Detected via comment'
    WHEN LOWER(c.column_name) RLIKE '.*(email|phone|name).*' THEN 'Detected via name'
    ELSE 'Not detected'
  END as detection_method
FROM information_schema.columns c
LEFT JOIN system.information_schema.column_tags ct
  ON c.table_catalog = ct.catalog_name
  AND c.table_schema = ct.schema_name 
  AND c.table_name = ct.table_name
  AND c.column_name = ct.column_name
WHERE c.table_catalog = 'your_catalog'
ORDER BY detection_method, table_name, column_name;
```

### Validate Function Logic
```sql
-- Test individual components
WITH test_data AS (
  SELECT 'test_email' as column_name, 'Contains email' as comment, 'email' as expected_type
  UNION ALL
  SELECT 'user_phone' as column_name, '' as comment, 'phone' as expected_type
)
SELECT 
  column_name,
  comment,
  expected_type,
  CASE 
    WHEN LOWER(column_name) RLIKE '.*(email|e_mail).*' THEN 'email'
    WHEN LOWER(column_name) RLIKE '.*(phone|tel|mobile).*' THEN 'phone'
    ELSE 'none'
  END as detected_type
FROM test_data;
```

## Getting Help

### Before Opening an Issue

1. **Check the logs** for specific error messages
2. **Verify permissions** on all required schemas
3. **Test with a small dataset** first
4. **Review configuration** settings

### Information to Include in Issues

- **Databricks Runtime version**
- **Unity Catalog version**
- **Complete error message**
- **SQL query that failed**
- **Catalog and schema names**
- **Expected vs. actual behavior**

### Performance Optimization Tips

1. **Start small** - Test with one schema before running on entire catalog
2. **Use appropriate cluster size** - Multi-node for large catalogs
3. **Cache frequently accessed data** - Create materialized views
4. **Filter early** - Use WHERE clauses to limit scope
5. **Monitor resource usage** - Check Spark UI for bottlenecks

## Contact Support

- **GitHub Issues**: [https://github.com/sumitsaraswat/ccpa-agent/issues](https://github.com/sumitsaraswat/ccpa-agent/issues)
- **Discussions**: [https://github.com/sumitsaraswat/ccpa-agent/discussions](https://github.com/sumitsaraswat/ccpa-agent/discussions)
- **Documentation**: Check the `docs/` folder for additional guides
