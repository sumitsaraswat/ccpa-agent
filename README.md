# CCPA Agent

## Overview

CCPA Agent is an open-source toolkit designed to streamline compliance with the California Consumer Privacy Act (CCPA) on Databricks. It offers automated functions to detect, classify, and manage personal information across Unity Catalog tables, and provides tools to estimate the impact and effort associated with consumer requests (delete, opt-out, right to know).

## Features

- **Automated PII Discovery and Classification** – SQL functions to inventory personal information across your catalog, using column tags, comments, and naming patterns.
- **Consumer Request Impact Analysis** – Evaluate how delete, opt-out, and right-to-know requests affect your tables and systems, with estimated record counts and effort.
- **Example Workflows and Dashboards** – Sample queries for executive reporting, risk assessment, and compliance workflows.
- **Extensive Documentation** – Installation, configuration, troubleshooting, and customization guides are provided in the `docs` folder.
- **Issue Templates** – Standardized templates to report bugs or request features in the `.github/ISSUE_TEMPLATE` directory.

## Repository Structure

```
ccpa-agent/
├── notebooks/               # Jupyter notebooks containing full implementation of the SQL functions
├── sql/                     # SQL scripts to set up schemas and create functions
├── examples/                # Example SQL queries for common use cases
├── docs/                    # Installation, configuration, and troubleshooting guides
└── .github/ISSUE_TEMPLATE/  # Issue templates for bugs and feature requests
```

## Getting Started

1. **Install** – Follow the step-by-step installation guide in `docs/installation.md` to create the compliance schema, run the notebooks, and set up permissions.
2. **Configure** – Customize PII detection, retention policies, and business logic using the instructions in `docs/configuration.md`.
3. **Run Examples** – Explore the `examples` directory to learn how to generate inventories, analyze consumer requests, and create executive reports.
4. **Troubleshoot** – If you encounter issues, consult `docs/troubleshooting.md` for common problems and solutions.

## Usage

The core functions are defined in the notebooks and compiled into SQL using the scripts in `sql/`. After installation, you can call them like any other function:

```sql
-- Inventory all PII across your catalog
SELECT * FROM compliance.ccpa_data_inventory();

-- Analyze a deletion request for a specific user
SELECT * 
FROM compliance.ccpa_consumer_request_impact(
  'john.doe@example.com',
  'email',
  'delete'
);
```

More detailed examples are available in `examples/basic_usage.sql`, `executive_reporting.sql`, and `compliance_workflows.sql`.


## License

This project is licensed under the MIT License – see the `LICENSE` file for details.

## Support

For questions or support, please refer to the documentation in the `docs` folder or open a discussion on the GitHub repository.
