# OlistFlow ETL - Project README

OlistFlow ETL processes the Brazilian Olist e-commerce dataset through a complete AWS serverless pipeline. The project transforms raw CSV files into curated Parquet tables and loads them into PostgreSQL for analytics reporting.

## 🎯 Project Overview
**OlistFlow ETL** demonstrates production-grade data engineering practices:

- **Infrastructure**: Terraform-provisioned VPC, S3 data lake (raw/curated), RDS PostgreSQL, AWS Glue 4.0 jobs
- **ETL Pipeline**: PySpark DynamicFrames processing Olist orders/customers/products (2016-2018)
- **CI/CD**: GitHub Actions OIDC workflows for PR plan/main apply
- **Repo**: [github.com/capstne/olistflow-etl](https://github.com/capstne/olistflow-etl)

## 🏗️ Architecture
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

## ✅ Major Achievements

### Infrastructure Provisioning
* ✅ VPC + Private Subnets + Security Groups (self-referencing Glue SG)
* ✅ S3 Buckets: raw/curated/artifacts (server-side encryption)
* ✅ RDS PostgreSQL (private, Multi-AZ ready)
* ✅ Glue 4.0 Jobs + Databases + JDBC Connections
* ✅ Lake Formation disabled (IAM_ALLOWED_PRINCIPALS Super)
* ✅ EC2 Instance for providing secure access to RDS database
* ✅ Windows script that installs pg admin 4 on EC2 and moves init.sql, postgres server template scripts into instance 
* ✅ Monitoring and email alerts for failed Glue jobs. 

### ETL Implementation

* ✅ raw_to_curated.py: DynamicFrame joins/filters → Parquet
* ✅ curated_to_rds.py: JDBC write fact_orders, dim_product, dim_sellers, dim_customers (TRUNCATE preactions)
* ✅ Spark catalog fixes: glueContext.create_dynamic_frame.from_catalog()
​

### Production Troubleshooting
- **Fixed**: Lake Formation blocking Glue databases → IAM Super permissions
- **Fixed**: JDBC "connection attempt failed" → VPC subnet/SG alignment
- **Fixed**: `url` key error → from_jdbc_conf with explicit connectionName

## 🚀 Quick Start

This assumes you have installed [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html), [git](https://git-scm.com/install/), [terraform CLI](https://developer.hashicorp.com/terraform/install) and [authenticated your computer with AWS.](https://docs.aws.amazon.com/cli/v1/userguide/cli-chap-authentication.html)

```bash
1. Clone & Setup
git clone https://github.com/capstne/olistflow-etl
cd olistflow-etl/infra

2. Initialize (dev environment)
terraform init 

3. Deploy full stack
terraform apply 

4. Upload Olist CSVs to raw bucket
aws s3 cp olist_dataset/ s3://olistflow-etl-dev-raw/olist/

5. Run ETL 
aws glue start-job-run --job-name olistflow-etl-dev-raw-to-curated
aws glue start-job-run --job-name olistflow-etl-dev-curated-to-rds

6. or run Step Function
# replace state machine arn with current value
aws stepfunctions start-execution --state-machine-arn arn:aws:states:us-east-1:{account}:stateMachine:olistflow-etl-dev-orchestrator 

```

📁 Repository Structure

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

🛠️ Technologies

```bash
| Category   | Technologies                                          |
| ---------- | ----------------------------------------------------- |
| IaC        | Terraform, EC2, GitHub Actions OIDC                        |
| Data       | S3, Glue Data Catalog, Parquet, PostgreSQL            |
| ETL        | AWS Glue 4.0 PySpark, DynamicFrames, JDBC             |
| Networking | VPC, NAT Gateway, Security Groups, VPC Endpoints      |
| Security   | IAM Roles, Lake Formation (IAM mode), Secrets Manager |

```

🎉 Key Learnings
* Glue Networking: Jobs must match RDS VPC/subnet/SG exactly

* Lake Formation: IAM_ALLOWED_PRINCIPALS Super = IAM-only mode

* PySpark: Use glueContext.create_dynamic_frame over spark.sql

* JDBC Writes: from_jdbc_conf + explicit connectionName > connection_options

🔮 Next Steps
* QuickSight dashboards (revenue/customer analytics)

* Cost monitoring + prod environment tfvars

* Data quality tests (Great Expectations)

 📈 Business Value
* Transforms 100K+ Olist orders into star schema for:

* Revenue analysis by seller/period

* Customer segmentation + LTV

* Delivery performance KPIs

* Product performance ranking

⭐ Built for portfolio showcase - Complete data platform from raw ingest to analytics-ready mart.

