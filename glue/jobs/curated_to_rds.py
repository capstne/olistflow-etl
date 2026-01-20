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
    'JDBC_CONNECTION_NAME',
    'URL'
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

# Write to RDS Postgres via Glue JDBC connection (truncate + load).
curated_orders.write \
    .format("jdbc") \
    .option("url", args['URL']) \
    .option("connectionName", args['JDBC_CONNECTION_NAME']) \
    .option("user", args['USER']) \
    .option("password", args['PASSWORD']) \
    .option("dbtable", "fact_orders") \
    .option("truncate", "true") \
    .option("driver", "org.postgresql.Driver") \
    .mode("overwrite") \
    .save()

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
