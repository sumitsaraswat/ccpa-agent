# Installation Guide

## Prerequisites

Before installing CCPA Agent, ensure you have:

- **Databricks Unity Catalog** environment (DBR 11.3+ recommended)
- **Permissions**:
  - `CREATE FUNCTION` and `CREATE VIEW` on your target schema
  - `SELECT` access to `information_schema` and `system.information_schema`
  - `USE CATALOG` and `USE SCHEMA` permissions

## Step-by-Step Installation

### 1. Prepare Your Environment

```sql
-- Check your current environment
SELECT CURRENT_CATALOG(), CURRENT_SCHEMA();

-- Verify you can access information schema
SELECT COUNT(*) FROM information_schema.tables LIMIT 5;
```

### 2. Create Compliance Schema

```sql
-- Replace 'your_catalog' with your actual catalog name
USE CATALOG your_catalog;

-- Create the compliance schema
CREATE SCHEMA IF NOT EXISTS compliance
COMMENT 'CCPA compliance automation functions and views';

USE SCHEMA compliance;
```

### 3. Upload and Execute Notebooks

1. **Download the notebooks** from the repository:
   - `notebooks/UCF_ccpa_data_inven.ipynb`
   - `notebooks/UCF_ccpa_consumer_request_impact.ipynb`

2. **Upload to Databricks**:
   - Go to your Databricks workspace
   - Navigate to your desired folder
   - Click "Import" and upload both notebooks

3. **Update catalog references**:
   - Open each notebook
   - Find and replace all instances of `sumitsaraswat_catalog` with your actual catalog name
   - Update the `USE CATALOG` statements

4. **Execute the notebooks**:
   - Run `UCF_ccpa_data_inven.ipynb` first (creates the base inventory function)
   - Run `UCF_ccpa_consumer_request_impact.ipynb` second (creates impact analysis)

### 4. Verify Installation

```sql
-- Check that functions were created successfully
SHOW FUNCTIONS IN compliance;

-- Test the data inventory function
SELECT COUNT(*) FROM compliance.ccpa_data_inventory();

-- Test the consumer request impact function
SELECT COUNT(*) FROM compliance.ccpa_consumer_request_impact();
```

### 5. Configure Permissions (Optional)

```sql
-- Grant permissions to your compliance team
GRANT SELECT ON SCHEMA compliance TO `compliance_team`;
GRANT EXECUTE ON SCHEMA compliance TO `compliance_team`;

-- Grant to data engineers for maintenance
GRANT CREATE ON SCHEMA compliance TO `data_engineers`;
```

## Troubleshooting

### Common Issues

**Issue**: "Catalog not found" error
```sql
-- Solution: Verify catalog name and permissions
SHOW CATALOGS;
```

**Issue**: "Permission denied on information_schema"
```sql
-- Solution: Contact your admin to grant information_schema access
-- You need SELECT permissions on information_schema.columns and information_schema.tables
```

**Issue**: Functions created but return no data
```sql
-- Solution: Check if your catalog has any tables with PII column names
-- Test with sample data first
```

### Validation Queries

```sql
-- Validate PII detection is working
SELECT 
  table_schema,
  table_name,
  column_name,
  data_type
FROM information_schema.columns 
WHERE table_catalog = 'your_catalog'
  AND (
    LOWER(column_name) LIKE '%email%' OR
    LOWER(column_name) LIKE '%phone%' OR
    LOWER(column_name) LIKE '%name%'
  )
LIMIT 10;
```

## Next Steps

After successful installation:

1. **Review the examples** in the `examples/` folder
2. **Configure PII detection** by adding column tags or comments
3. **Run compliance reports** using the executive reporting examples
4. **Set up regular monitoring** of compliance status

## Support

If you encounter issues:

1. Check the [troubleshooting guide](troubleshooting.md)
2. Review the [configuration documentation](configuration.md)
3. Open an issue on [GitHub](https://github.com/sumitsaraswat/ccpa-agent/issues)
