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
    'RAW_DB',
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

dim_customers = glueContext.create_dynamic_frame.from_catalog(
    database=args['RAW_DB'],
    table_name="olist_customers_dataset_csv"
).toDF()

dim_products = glueContext.create_dynamic_frame.from_catalog(
    database=args['RAW_DB'],
    table_name="olist_products_dataset_csv"
).toDF()

dim_sellers = glueContext.create_dynamic_frame.from_catalog(
    database=args['RAW_DB'],
    table_name="olist_sellers_dataset_csv"
).toDF()

glueContext.write_dynamic_frame.from_jdbc_conf(
    frame=DynamicFrame.fromDF(curated_orders, glueContext, "df"),
    catalog_connection=args['JDBC_CONNECTION_NAME'],
    connection_options={
        "database": "postgres",
        "dbtable": "olistflow.fact_orders",
        "preactions": "TRUNCATE TABLE olistflow.fact_orders;"
    }
)

glueContext.write_dynamic_frame.from_jdbc_conf(
    frame=DynamicFrame.fromDF(dim_customers, glueContext, "df"),
    catalog_connection=args['JDBC_CONNECTION_NAME'],
    connection_options={
        "database": "postgres",
        "dbtable": "olistflow.dim_customers",
        "preactions": "TRUNCATE TABLE olistflow.dim_customers;"
    }
)

glueContext.write_dynamic_frame.from_jdbc_conf(
    frame=DynamicFrame.fromDF(dim_products['product_id', 'product_category_name'], glueContext, "df"),
    catalog_connection=args['JDBC_CONNECTION_NAME'],
    connection_options={
        "database": "postgres",
        "dbtable": "olistflow.dim_products",
        "preactions": "TRUNCATE TABLE olistflow.dim_products;"
    }
)

glueContext.write_dynamic_frame.from_jdbc_conf(
    frame=DynamicFrame.fromDF(dim_sellers, glueContext, "df"),
    catalog_connection=args['JDBC_CONNECTION_NAME'],
    connection_options={
        "database": "postgres",
        "dbtable": "olistflow.dim_sellers",
        "preactions": "TRUNCATE TABLE olistflow.dim_sellers;"
    }
)

job.commit()
