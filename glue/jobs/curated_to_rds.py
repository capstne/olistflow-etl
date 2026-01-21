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
    'JDBC_CONNECTION_NAME'
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

glueContext.write_dynamic_frame.from_jdbc_conf(
    frame=DynamicFrame.fromDF(curated_orders, glueContext, "df"),
    catalog_connection=args['JDBC_CONNECTION_NAME'],
    connection_options={
        "database": "postgres",
        "dbtable": "olistflow.fact_orders",
        "preactions": "TRUNCATE TABLE fact_orders;"
    }
)

job.commit()
