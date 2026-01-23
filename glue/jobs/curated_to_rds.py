import boto3
import sys
import psycopg2

from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from awsglue.dynamicframe import DynamicFrame
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from pyspark.sql import functions as F
from pyspark.sql.functions import col, to_date
from urllib.parse import urlparse

args = getResolvedOptions(sys.argv, [
    'JOB_NAME',
    'CURATED_DB',
    'RAW_DB',
    'JDBC_CONNECTION_NAME'
])

sc = SparkContext()
glue_context = GlueContext(sc)
job = Job(glue_context)
job.init(args['JOB_NAME'], args)

def func_write_dynamic_frame(my_glue_context, my_dataframe, my_catalog_connection, my_destination_table):
    my_glue_context.write_dynamic_frame.from_jdbc_conf(
        frame=DynamicFrame.fromDF(my_dataframe, my_glue_context),
        catalog_connection=my_catalog_connection,
        connection_options={
            "database": "postgres",
            "dbtable": "olistflow.{}".format(my_destination_table)
        }
    )
    
def func_get_dataframe(my_glue_context, my_database, my_table):
    return my_glue_context.create_dynamic_frame.from_catalog(
        database=my_database,
        table_name=my_table
    ).toDF()

def func_get_connection_properties(my_glue_client):
    resp = my_glue_client.get_connection(
        Name=args["JDBC_CONNECTION_NAME"],
        HidePassword=False
    )
    props = resp["Connection"]["ConnectionProperties"]
    return props

def func_truncate_all_tables(my_connection_properties):
    jdbc_url = my_connection_properties["JDBC_CONNECTION_URL"]
    user     = my_connection_properties.get("USERNAME")
    password = my_connection_properties.get("PASSWORD") 
    
    parsed = urlparse(jdbc_url.replace("jdbc:", "", 1))
    host = parsed.hostname
    port = parsed.port
    dbname = parsed.path.lstrip("/")  # "postgres"
    
    conn = psycopg2.connect(
        host=host,
        dbname=dbname,
        user=user,
        password=password,
        port=port,
    )
    
    conn.autocommit = True
    
    with conn.cursor() as cur:
        cur.execute("""
        TRUNCATE TABLE olistflow.fact_orders, 
            olistflow.dim_sellers, 
            olistflow.dim_products, 
            olistflow.dim_customers 
        RESTART IDENTITY;
        """) 
        
glue_client = boto3.client("glue")
db_connection_properties = func_get_connection_properties(glue_client)

# truncate all tables
func_truncate_all_tables(db_connection_properties)

# load all dimensions tables first
dim_customers = func_get_dataframe(glue_context, args['RAW_DB'], 'olist_customers_dataset_csv')
dim_customers = dim_customers \
  .withColumnRenamed("customer_zip_code_prefix","zip_code_prefix") \
  .withColumnRenamed("customer_city","city") \
  .withColumnRenamed("customer_state","state")
func_write_dynamic_frame(glue_context, dim_customers, args['JDBC_CONNECTION_NAME'], 'dim_customers')

dim_products = func_get_dataframe(glue_context, args['RAW_DB'], 'olist_products_dataset_csv')
dim_products = dim_products['product_id', 'product_category_name']
func_write_dynamic_frame(glue_context, dim_products, args['JDBC_CONNECTION_NAME'], 'dim_products')

dim_sellers = func_get_dataframe(glue_context, args['RAW_DB'], 'olist_sellers_dataset_csv')
func_write_dynamic_frame(glue_context, dim_sellers, args['JDBC_CONNECTION_NAME'], 'dim_sellers')

# then load the fact table
curated_orders = func_get_dataframe(glue_context, args['CURATED_DB'], 'orders')
curated_orders = curated_orders.withColumn("order_date", to_date(col("order_date"), "yyyy-MM-dd")) 

func_write_dynamic_frame(glue_context, curated_orders, args['JDBC_CONNECTION_NAME'], 'fact_orders')

job.commit()
