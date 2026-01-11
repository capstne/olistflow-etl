import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from pyspark.sql import functions as F

args = getResolvedOptions(sys.argv, [
    'JOB_NAME',
    'CURATED_DB',
    'JDBC_CONNECTION_NAME'
])

sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args['JOB_NAME'], args)

# Load curated orders.
curated_orders = spark.table(f"{args['CURATED_DB']}.curated_orders")

# Write to RDS Postgres via Glue JDBC connection (truncate + load).
curated_orders.write \
    .format("jdbc") \
    .option("connectionName", args['JDBC_CONNECTION_NAME']) \
    .option("dbtable", "fact_orders") \
    .option("truncate", "true") \
    .mode("overwrite") \
    .save()

# Also write dims (simple extracts).
dims = curated_orders.select(
    "customer_id", "customer_unique_id", "customer_zip_code_prefix",
    "customer_city", "customer_state"
).distinct()

dims.write \
    .format("jdbc") \
    .option("connectionName", args['JDBC_CONNECTION_NAME']) \
    .option("dbtable", "dim_customers") \
    .option("truncate", "true") \
    .mode("overwrite") \
    .save()

job.commit()
