import boto3
import sys
import psycopg2

from awsglue.context import GlueContext
from awsglue.dynamicframe import DynamicFrame
from awsglue.job import Job
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from pyspark.sql.functions import col, to_date
from urllib.parse import urlparse

args = getResolvedOptions(sys.argv, [
    'JOB_NAME',
    'CURATED_DB',
    'RAW_DB',
    'JDBC_CONNECTION_NAME'
])

db_tables = {
    'customers': 'olistflow.dim_customers',
    'products': 'olistflow.dim_products',
    'sellers': 'olistflow.dim_sellers',
    'orders': 'olistflow.fact_orders',
}

sc = SparkContext()
glue_context = GlueContext(sc)
logger = glue_context.get_logger()

job = Job(glue_context)
job.init(args['JOB_NAME'], args)

def func_write_dynamic_frame(my_glue_context, my_dataframe, my_catalog_connection, my_dbtable, my_database):
    try:
        logger.info('Creating a DynamicFrame from DataFrame ({0}).'.format(my_dataframe))
        my_dynamic_frame  = DynamicFrame.fromDF(my_dataframe, my_glue_context)

        logger.info('Writing Dynamic Frame ({0}) into dbtable ({1})'.format(my_dynamic_frame, my_dbtable))
        my_glue_context.write_dynamic_frame.from_jdbc_conf(
            frame=my_dynamic_frame,
            catalog_connection=my_catalog_connection,
            connection_options={
                'database': my_database,
                'dbtable': my_dbtable
            }
        )
    except Exception as e:
        logger.error('Error: {0}'.format(e))
        raise

    
def func_get_dataframe(my_glue_context, my_database, my_table):
    logger.info('Creating a DataFrame from GlueTable ({0}) in Database ({1}).'.format(my_table, my_database))
    try:
        return my_glue_context.create_dynamic_frame.from_catalog(
            database=my_database,
            table_name=my_table
        ).toDF()
    except Exception as e:
        logger.error('Error: {0}'.format(e))
        raise

def func_get_connection_properties(my_glue_client):
    logger.info('Retrieving DB Connection properties.')
    try:
        resp = my_glue_client.get_connection(
            Name=args['JDBC_CONNECTION_NAME'],
            HidePassword=False
        )
        props = resp['Connection']['ConnectionProperties']
        return props
    except Exception as e:
        logger.error('Error: {0}'.format(e))
        raise

def func_format_connection_properties(my_connection_properties):
    logger.info('Formatting connection properties..')

    jdbc_url = my_connection_properties.get('JDBC_CONNECTION_URL', None)
    user     = my_connection_properties.get('USERNAME', None)
    password = my_connection_properties.get('PASSWORD', None) 
    
    parsed = urlparse(jdbc_url.replace('jdbc:', '', 1))
    host = parsed.hostname
    port = parsed.port
    dbname = parsed.path.lstrip('/')  

    return {
        'host': host,
        'dbname': dbname,
        'user': user,
        'password': password,
        'port': port
    }

def func_truncate_all_tables(my_formatted_connection_properties, my_tables):
    logger.info('Starting truncate_all_tables function, connecting to DB...')

    try:
        conn = psycopg2.connect(            
            host=my_formatted_connection_properties['host'],
            dbname=my_formatted_connection_properties['dbname'],
            user=my_formatted_connection_properties['user'],
            password=my_formatted_connection_properties['password'],
            port=my_formatted_connection_properties['port']
        )
        conn.autocommit = True
        
        sql_statement = '''TRUNCATE TABLE {0}, {1}, {2}, {3} RESTART IDENTITY;
             '''.format(my_tables['orders'], my_tables['sellers'], my_tables['products'], my_tables['customers'])
        
        with conn.cursor() as cur:
            cur.execute(sql_statement) 
    except Exception as e:
        logger.error('Error: {0}'.format(e))
        raise
        
glue_client = boto3.client('glue')
db_connection_properties = func_get_connection_properties(glue_client)
formatted_connection_properties = func_format_connection_properties(db_connection_properties)

# truncate all tables
func_truncate_all_tables(formatted_connection_properties, db_tables)

# load all dimensions tables first
dim_customers = func_get_dataframe(glue_context, args['RAW_DB'], 'olist_customers_dataset_csv')
dim_customers = dim_customers \
  .withColumnRenamed('customer_zip_code_prefix','zip_code_prefix') \
  .withColumnRenamed('customer_city','city') \
  .withColumnRenamed('customer_state','state')
func_write_dynamic_frame(glue_context, dim_customers, args['JDBC_CONNECTION_NAME'], db_tables['customers'], formatted_connection_properties['dbname'])

dim_products = func_get_dataframe(glue_context, args['RAW_DB'], 'olist_products_dataset_csv')
dim_products = dim_products['product_id', 'product_category_name']
func_write_dynamic_frame(glue_context, dim_products, args['JDBC_CONNECTION_NAME'], db_tables['products'], formatted_connection_properties['dbname'])

dim_sellers = func_get_dataframe(glue_context, args['RAW_DB'], 'olist_sellers_dataset_csv')
func_write_dynamic_frame(glue_context, dim_sellers, args['JDBC_CONNECTION_NAME'], db_tables['sellers'], formatted_connection_properties['dbname'])

# then load the fact table
curated_orders = func_get_dataframe(glue_context, args['CURATED_DB'], 'orders')
curated_orders = curated_orders.withColumn('order_date', to_date(col('order_date'), 'yyyy-MM-dd')) 

func_write_dynamic_frame(glue_context, curated_orders, args['JDBC_CONNECTION_NAME'], db_tables['orders'], formatted_connection_properties['dbname'])

job.commit()