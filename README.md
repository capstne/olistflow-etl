# OlistFlow ETL

[![Terraform](https://img.shields.io/badge/IaC-Terraform-purple)]()
[![AWS Glue](https://img.shields.io/badge/ETL-AWS%20Glue-orange)]()
[![PostgreSQL](https://img.shields.io/badge/Warehouse-PostgreSQL-blue)]()

Production-grade AWS serverless ETL pipeline transforming Olist e-commerce data into an analytics-ready denormalized order mart.

## Project Overview
**OlistFlow ETL** demonstrates production-grade data engineering practices:

- **Infrastructure**: Terraform-provisioned VPC, S3 data lake (raw/curated), RDS PostgreSQL, AWS Glue 4.0 jobs
- **ETL Pipeline**: PySpark DynamicFrames processing Olist orders/customers/products (2016-2018)
- **CI/CD**: GitHub Actions OIDC workflows for PR plan/main apply
- **Orchestration**: AWS Step Functions state machine

## Highlights

- 100K+ e-commerce orders processed
- AWS serverless architecture
- Terraform-managed infrastructure
- Denormalized order-centric warehouse model
- GitHub Actions OIDC CI/CD
- End-to-end orchestration via Step Functions


## Architecture
![Architecture](docs/images/0.%20olistflow%20-%20architecture_diagram.jpg)

```bash
Raw CSVs (Olist Kaggle) 
    ↓ S3 olistflow-etl-dev-raw
Glue raw_to_curated.py
    ↓ S3 olistflow-etl-dev-curated (Parquet)
Glue curated_to_rds.py  
    ↓ RDS PostgreSQL fact_orders/dim_* tables (VPC private)
```
**Key Components**:
- **Networking**: Private VPC + NAT Gateway + S3 VPC Endpoint + Glue/RDS Security Groups
- **Data Catalog**: Glue databases `olistflow_etl_raw` / `olistflow_etl_curated`
- **Step Function**: State Machine orchestrator `olistflow-etl-dev-orchestrator` 
- **IAM**: Least-privilege roles + OIDC GitHub Actions provider

## Resume Summary

Built an AWS-based ETL platform using Terraform, Glue, Step Functions, S3, and PostgreSQL to process 100K+ e-commerce orders into an analytics-ready order mart with automated infrastructure provisioning, orchestration, and CI/CD deployment.

## Architecture Decisions

### Why Glue instead of Lambda?
The transformation workload exceeded Lambda execution limits and benefited from Spark-based distributed processing.

### Why Parquet?
Columnar storage reduced storage footprint and improved analytical query performance.

### Why PostgreSQL instead of Redshift?
The dataset size (~100K orders) did not justify a dedicated analytics warehouse.

---

## Data Discovery

AWS Glue Crawlers catalog the raw Olist datasets and create metadata tables for downstream processing.

![Glue Crawler](docs/images/1.%20olistflow%20-%20crawler.png)

---


## Raw Data Catalog

Raw datasets are registered in the Glue Data Catalog and made available for ETL processing.

![Raw Database](docs/images/2.%20olistflow%20-%20raw_db.png)

---

## Raw to Curated ETL

The first Glue job transforms raw CSV datasets into optimized Parquet files stored in the curated data lake.

![Raw to Curated Job](docs/images/3.%20olistflow%20-%20etl_dev_raw_to_curated.png)

---

## Secure Bastion Access

A Windows bastion host provides secure administrative access to the private PostgreSQL database using pgAdmin 4.

![Windows Bastion](docs/images/4.%20olistflow%20-%20windows%20bastion.png)

---

## Warehouse Schema Initialization

Database tables are automatically created through the initialization scripts deployed during infrastructure provisioning.

![SQL Tables Created](docs/images/5.%20olistflow%20-%20sql%20tables%20created.png)

---

## Curated to RDS ETL

The second Glue job loads curated Parquet datasets into PostgreSQL dimension and fact tables.

![Curated to RDS Job](docs/images/6.%20olistflow%20-%20etl_dev_curated_to_rds.png)

---

## Monitoring & Alerting

CloudWatch alarms and SNS notifications provide operational visibility and alert on ETL failures.

![Glue Failure Alert](docs/images/7.%20olistflow%20-%20alert%20for%20glue%20job%20failure.png)

---

## Analytics Warehouse

The completed denormalized order mart enables reporting, customer analytics, and operational KPI tracking.

![Data Model](docs/images/10.%20olistflow%20-%20datamodel.png)

---

## Pipeline Orchestration

AWS Step Functions orchestrates the end-to-end ETL workflow from raw ingestion through warehouse loading.

![Step Functions](docs/images/9.%20olistflow%20-%20step%20functions.png)

## ✅ Major Achievements

### Infrastructure Provisioning
* ✅ VPC + Private Subnets + Security Groups (self-referencing Glue SG)
* ✅ S3 Buckets: raw/curated/artifacts (server-side encryption)
* ✅ RDS PostgreSQL (private, Multi-AZ ready)
* ✅ Glue 4.0 Jobs + Databases + JDBC Connections
* ✅ Lake Formation disabled (IAM_ALLOWED_PRINCIPALS Super)
* ✅ EC2 Instance for providing secure access to RDS database
* ✅ Windows script that installs pg admin 4 on EC2 and moves init.sql, postgres server template scripts into instance, saves the server connection details in pgAdmin 4 and executes init.sql - creating the relevant tables. 
* ✅ Monitoring and email alerts for failed Glue jobs. 

### ETL Implementation

* ✅ raw_to_curated.py: Multi-source joins (orders, customers, products, sellers, payments, reviews) → curated Parquet datasets
* ✅ curated_to_rds.py: JDBC write fact_orders, dim_products, dim_sellers, dim_customers (TRUNCATE preactions)
* ✅ Spark catalog fixes: glueContext.create_dynamic_frame.from_catalog()
​

### Production Troubleshooting
- **Fixed**: Lake Formation blocking Glue databases → IAM Super permissions
- **Fixed**: JDBC "connection attempt failed" → VPC subnet/SG alignment
- **Fixed**: `url` key error → from_jdbc_conf with explicit connectionName

## Quick Start

This assumes you have installed [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html), [git](https://git-scm.com/install/), [terraform CLI](https://developer.hashicorp.com/terraform/install) and [authenticated your computer with AWS.](https://docs.aws.amazon.com/cli/v1/userguide/cli-chap-authentication.html)

```bash
1. Clone & Setup
git clone https://github.com/capstne/olistflow-etl
cd olistflow-etl/infra

2. Initialize (dev environment)
terraform init 

3. Deploy full stack
terraform apply

4. Start Crawler
aws glue start-crawler --name olistflow-etl-dev-raw-crawler

5. Run ETL 
aws glue start-job-run --job-name olistflow-etl-dev-raw-to-curated
aws glue start-job-run --job-name olistflow-etl-dev-curated-to-rds

6. or run Step Function
# replace state machine arn with current value
aws stepfunctions start-execution --state-machine-arn arn:aws:states:us-east-1:{account}:stateMachine:olistflow-etl-dev-orchestrator 

```
You can then go to s3://olistflow-etl-dev-curated on your AWS console to either view the fact table as a parquet file, or access the RDS DB instance - via pgAdmin 4 on EC2 - using the secrets **olistflow-etl-dev-bastion-keypair** for getting [EC2 password using the private key](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-key-pairs.html) and **olistflow-etl-dev-rds-master-password** for authenticating to the DB. 

pgAdmin 4 has already been installed along with relevant server connection creds using the provided powershell script (olistflow-etl/scripts/windows/windows-userdata.ps1).

## Repository Structure

```bash
.
├── README.md
├── data
│   └── olist                                       # raw data from kaggle
│       ├── olist_customers_dataset.csv
│       ├── olist_order_items_dataset.csv
│       ├── olist_order_payments_dataset.csv
│       ├── olist_order_reviews_dataset.csv
│       ├── olist_orders_dataset.csv
│       ├── olist_products_dataset.csv
│       └── olist_sellers_dataset.csv
├── glue                                            # ✨ PySpark ETL jobs
│   └── jobs
│       ├── curated_to_rds.py
│       └── raw_to_curated.py
├── infra                                           # 🏗️ Terraform IaC
│   ├── alerts.tf
│   ├── backend.tf
│   ├── bastion.tf
│   ├── glue.tf
│   ├── glue_connection.tf
│   ├── iam.tf
│   ├── lakeformation.tf
│   ├── main.tf
│   ├── outputs.tf
│   ├── pgadmin.tf
│   ├── rds.tf
│   ├── s3.tf
│   ├── s3gateway.tf
│   ├── secrets.tf
│   ├── step_functions.tf
│   ├── stepfunctions
│   │   └── olistflow_etl.asl.json.tpl
│   ├── variables.tf
│   ├── versions.tf
│   └── vpc.tf
├── scripts                                         # SQL and windows scripts
│   ├── sql
│   │   └── init.sql
│   └── windows
│       └── windows-userdata.ps1
└── templates                                       # postgres sql server connection file template
    └── servers.json.tmpl
```

## Technologies

| Category   | Technologies                                          |
| ---------- | ----------------------------------------------------- |
| IaC        | Terraform, EC2, GitHub Actions OIDC                   |
| Data       | S3, Glue Data Catalog, Parquet, PostgreSQL            |
| ETL        | AWS Glue 4.0 PySpark, DynamicFrames, JDBC             |
| Networking | VPC, NAT Gateway, Security Groups, VPC Endpoints      |
| Security   | IAM Roles, Lake Formation (IAM mode), Secrets Manager |

## Cost Considerations

Development environment costs approximately:
- NAT Gateway: ~$32/month
- RDS db.t4g.micro: ~$15/month
- S3: <$1/month
- Glue Jobs: Pay-per-use

Project is intended for learning and demonstration purposes.

## Data Model

The warehouse currently implements an order-centric analytics model. Customer attributes are joined into the fact table to support customer segmentation and order-level reporting.

Future enhancements will introduce order-item fact tables to support seller and product analytics at a finer grain.

The current model intentionally aggregates data at the order grain to simplify analytics while validating the end-to-end ETL platform.

![Fact Table Loaded](docs/images/10.%20olistflow%20-%20datamodel.png)

## Key Learnings
* Glue Networking: Jobs must match RDS VPC/subnet/SG exactly

* Lake Formation: IAM_ALLOWED_PRINCIPALS Super = IAM-only mode

* PySpark: Use glueContext.create_dynamic_frame over spark.sql

* JDBC Writes: from_jdbc_conf + explicit connectionName > connection_options

## Next Steps
* QuickSight dashboards (revenue/customer analytics)

* Cost monitoring + prod environment tfvars

* Data quality tests (Great Expectations)

* Order-item fact table for seller and product analytics

## Business Value
* Transforms 100K+ Olist orders into denormalized order mart for:

* Revenue analysis by reporting period
* Customer segmentation and purchase behavior analysis
* Delivery performance KPI reporting
* Order status and review score analytics

## Project Scope

Completed over 3 weeks as a self-directed data engineering project.

Built for portfolio showcase - Complete data platform from raw ingest to analytics-ready mart.

