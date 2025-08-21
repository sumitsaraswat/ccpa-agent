# Configuration Guide

## Overview

CCPA Agent uses a three-tiered approach to detect PII, in order of priority:
1. **Column Tags** (highest priority)
2. **Column Comments/Descriptions** (medium priority)
3. **Column Name Patterns** (fallback)

## PII Detection Configuration

### Method 1: Column Tags (Recommended)

Column tags provide the most reliable PII detection method.

```sql
-- Tag columns with specific PII types
ALTER TABLE your_schema.customer_data 
ALTER COLUMN user_email 
SET TAGS ('pii_type' = 'email');

ALTER TABLE your_schema.customer_data 
ALTER COLUMN contact_phone 
SET TAGS ('pii_type' = 'phone');

ALTER TABLE your_schema.customer_data 
ALTER COLUMN customer_name 
SET TAGS ('pii_type' = 'name');

-- For non-PII columns (to prevent false detection)
ALTER TABLE your_schema.customer_data 
ALTER COLUMN user_id 
SET TAGS ('pii_type' = 'none');
```

**Supported PII Types:**
- `email` - Email addresses
- `phone` - Phone numbers
- `name` - Personal names (first, last, full)
- `ssn` - Social Security Numbers
- `credit_card` - Credit card numbers
- `address` - Physical addresses
- `dob` - Date of birth
- `ip_address` - IP addresses
- `none` - Explicitly mark as non-PII

### Method 2: Column Comments

Add descriptive comments that include PII keywords:

```sql
-- Add comments for PII detection
ALTER TABLE your_schema.mystery_table 
ALTER COLUMN col_123 
COMMENT 'Contains customer email addresses for marketing communications';

ALTER TABLE your_schema.data_table 
ALTER COLUMN field_abc 
COMMENT 'Customer phone number for support contact';

ALTER TABLE your_schema.user_info 
ALTER COLUMN personal_data 
COMMENT 'Social security number for tax reporting and compliance';
```

**Detection Keywords:**
- Email: `email`, `e-mail`, `electronic mail`
- Phone: `phone`, `telephone`, `mobile`, `cell`
- Name: `first name`, `last name`, `full name`, `customer name`
- SSN: `ssn`, `social security`, `tax id`
- Credit Card: `credit card`, `payment`, `card number`
- Address: `address`, `street`, `postal`, `mailing`
- DOB: `birth date`, `dob`, `date of birth`
- IP: `ip address`, `internet protocol`

### Method 3: Column Naming Conventions

Use standard naming patterns that will be automatically detected:

**Email Patterns:**
- `customer_email`, `user_email`, `email_address`
- `contact_email`, `billing_email`, `primary_email`

**Phone Patterns:**
- `phone_number`, `contact_phone`, `mobile_number`
- `home_phone`, `work_phone`, `cell_phone`

**Name Patterns:**
- `first_name`, `last_name`, `full_name`
- `customer_name`, `user_name`, `display_name`

**Address Patterns:**
- `street_address`, `mailing_address`, `billing_address`
- `address_line1`, `city`, `zip_code`, `postal_code`

## Business Configuration

### Retention Policies

Customize retention periods by modifying the function logic:

```sql
-- Default retention periods (in ccpa_data_inventory function)
CASE 
  WHEN pii_type IN ('email', 'phone', 'address') THEN '24 months after last interaction'
  WHEN pii_type IN ('name', 'ssn') THEN '7 years for business records'
  WHEN pii_type = 'credit_card' THEN '90 days maximum (encrypted)'
  WHEN pii_type = 'ip_address' THEN '12 months'
  ELSE 'Under review'
END
```

### Sale/Sharing Configuration

Customize data sharing status based on your business practices:

```sql
-- Update sale/sharing status (in ccpa_data_inventory function)
CASE 
  WHEN pii_type IN ('email', 'ip_address') THEN 'May be shared with marketing/analytics partners'
  WHEN pii_type IN ('phone', 'name', 'address') THEN 'Not sold, shared with service providers only'
  WHEN pii_type IN ('ssn', 'credit_card') THEN 'Never sold or shared (legal/service requirements only)'
  ELSE 'To be determined'
END
```

### Business Purpose Mapping

Customize business purposes for your organization:

```sql
-- Update business purposes (in ccpa_data_inventory function)
CASE 
  WHEN pii_type = 'email' THEN 'Customer communication, marketing, account management'
  WHEN pii_type = 'phone' THEN 'Customer service, account verification, security'
  WHEN pii_type = 'name' THEN 'Account management, service delivery, legal compliance'
  -- Add your specific business purposes here
END
```

## Advanced Configuration

### Custom PII Types

To add new PII types, update the detection logic:

```sql
-- Add to the PII detection CASE statement
WHEN UPPER(COALESCE(ct.tag_value, '')) RLIKE '.*(YOUR_CUSTOM_TYPE).*' THEN 'custom_type'
WHEN UPPER(COALESCE(c.comment, '')) RLIKE '.*(YOUR_KEYWORD).*' THEN 'custom_type'
WHEN LOWER(c.column_name) RLIKE '.*(your_pattern).*' THEN 'custom_type'
```

### Legal Hold Customization

Modify legal hold logic for your jurisdiction:

```sql
-- Update legal hold assessment
CASE 
  WHEN sensitive_personal_info = TRUE AND table_location RLIKE '.*tax.*|.*payroll.*' 
    THEN 'IRS 7-year retention requirement'
  WHEN table_location RLIKE '.*financial.*|.*transaction.*|.*billing.*' 
    THEN 'Subject to 7-year business records retention'
  -- Add your specific legal requirements here
END
```

### Complexity Assessment

Customize deletion complexity based on your systems:

```sql
-- Update complexity assessment
CASE 
  WHEN sensitive_personal_info = TRUE THEN 'High'
  WHEN table_location RLIKE '.*your_complex_system.*' THEN 'High'
  WHEN ccpa_category = 'Commercial Information' THEN 'Medium'
  -- Add your system-specific complexity rules
END
```
