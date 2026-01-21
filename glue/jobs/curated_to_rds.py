import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from awsglue.dynamicframe import DynamicFrame
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from pyspark.sql import functions as F

args = getResolvedOptions(sys.argv, [
    'JOB_NAME',
    'CURATED_DB',
    'JDBC_CONNECTION_NAME',
    'URL',
    'USERNAME',
    'PASSWORD'
])

sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args['JOB_NAME'], args)

curated_orders = glueContext.create_dynamic_frame.from_catalog(
    database=args['CURATED_DB'],
    table_name="orders"
).toDF()


glueContext.write_dynamic_frame.from_options(
    frame=DynamicFrame.fromDF(curated_orders, glueContext, "df"),
    connection_type="postgresql",
    connection_options={
        "connectionName": args["JDBC_CONNECTION_NAME"],
        "url": args["URL"],
        "username": args["USERNAME"],
        "password": args["PASSWORD"],
        "dbtable": "fact_orders",
        "database": "postgres",
        "preactions": "TRUNCATE TABLE fact_orders"
    }
)

## Write to RDS Postgres via Glue JDBC connection (truncate + load).
# curated_orders.write \
#     .format("jdbc") \
#     .option("url", "jdbc:postgresql://olistflow-etl-dev.ct6v1kobwsnl.us-east-1.rds.amazonaws.com:5432/postgres") \
#     .option("connectionName", args['JDBC_CONNECTION_NAME']) \
#     .option("dbtable", "fact_orders") \
#     .option("truncate", "true") \
#     .mode("overwrite") \
#     .save()

# # Also write dims (simple extracts).
# dims = curated_orders.select(
#     "customer_id", "customer_unique_id", "customer_zip_code_prefix",
#     "customer_city", "customer_state"
# ).distinct()

# dims.write \
#     .format("jdbc") \
#     .option("url", "jdbc:postgresql://your-rds-endpoint:5432/your_db_name") \ 
#     .option("connectionName", args['JDBC_CONNECTION_NAME']) \
#     .option("dbtable", "dim_customers") \
#     .option("truncate", "true") \
#     .mode("overwrite") \
#     .save()

job.commit()
