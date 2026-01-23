import awswrangler as wr
import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from pyspark.sql.functions import *
from pyspark.sql.types import *

args = getResolvedOptions(sys.argv, [
    'JOB_NAME',
    'RAW_BUCKET', 'RAW_PREFIX',
    'CURATED_BUCKET', 'CURATED_PREFIX',
    'RAW_DB', 'CURATED_DB'
])

sc = SparkContext()
glue_context = GlueContext(sc)
logger = glue_context.get_logger()

job = Job(glue_context)
job.init(args['JOB_NAME'], args)

def func_load_df_from_catalog(my_glue_context, my_db, my_table):
    logger.info('Loading {0} from Glue DB {1}.'.format(my_table, my_db))
    try:
        return my_glue_context.create_dynamic_frame.from_catalog(
            database=my_db,
            table_name=my_table
        ).toDF()
    except Exception as e:
        logger.error('Error: {0}'.format(e))


# Load via GlueContext
raw_orders_df = func_load_df_from_catalog(glue_context, args['RAW_DB'], 'olist_orders_dataset_csv')
raw_customers_df = func_load_df_from_catalog(glue_context, args['RAW_DB'], 'olist_customers_dataset_csv')
raw_items_df = func_load_df_from_catalog(glue_context, args['RAW_DB'], 'olist_order_items_dataset_csv')
raw_products_df = func_load_df_from_catalog(glue_context, args['RAW_DB'], 'olist_products_dataset_csv')
raw_payments_df = func_load_df_from_catalog(glue_context, args['RAW_DB'], 'olist_order_payments_dataset_csv')
raw_reviews_df = func_load_df_from_catalog(glue_context, args['RAW_DB'], 'olist_order_reviews_dataset_csv')
raw_sellers_df = func_load_df_from_catalog(glue_context, args['RAW_DB'], 'olist_sellers_dataset_csv')

# add order_date partition column (parse from order_purchase_timestamp).
raw_orders_df = raw_orders_df.withColumn(
    "order_date",
    to_date(col("order_purchase_timestamp"))
)

raw_sellers_df = raw_sellers_df.withColumnRenamed("seller_id", "raw_seller_id")

# curated orders (fact seed): join customers, items, products, payments, reviews, sellers, aggregate.
temp_joined = raw_orders_df \
    .join(raw_customers_df, "customer_id", "left") \
    .join(raw_items_df, "order_id", "left") \
    .join(raw_products_df, "product_id", "left") \
    .join(raw_payments_df, "order_id", "left") \
    .join(raw_reviews_df, "order_id", "left") \
    .join(raw_sellers_df, col("seller_id") == raw_sellers_df["raw_seller_id"], "left") 

# minimal groupBy: order_id + order_date, pick first of each (validates joins work).
curated_orders = temp_joined \
    .groupBy("order_id", "order_date") \
    .agg(
        first("customer_id").alias("customer_id"),
        first("customer_unique_id").alias("customer_unique_id"),
        first("customer_zip_code_prefix").alias("customer_zip_code_prefix"),
        first("customer_city").alias("customer_city"),
        first("customer_state").alias("customer_state"),
        first("price").alias("total_price"),  
        first("freight_value").alias("total_freight"),
        first("payment_installments").alias("installments"),
        first("payment_sequential").alias("payment_count"),
        first("order_status").alias("order_status"),
        first("review_score").alias("review_score")
    ) \
    .select(
        col("order_id"),
        col("order_date").cast(DateType()),
        col("customer_id"),
        col("customer_unique_id"),
        col("customer_zip_code_prefix").cast(IntegerType()),
        col("customer_city"),
        col("customer_state"),
        col("total_price").cast(DoubleType()),
        col("total_freight").cast(DoubleType()),
        col("installments").cast(IntegerType()),
        col("payment_count").cast(IntegerType()),
        col("order_status"),
        col("review_score").cast(FloatType())
    )

# convert to pandas
curated_orders_p_df = curated_orders.toPandas()

wr.s3.to_parquet(
    df=curated_orders_p_df,
    path=f"s3://{args['CURATED_BUCKET']}/{args['CURATED_PREFIX']}orders/",
    dataset=True,
    database=args['CURATED_DB'],
    table="orders",
    mode="overwrite",
    partition_cols=['order_date']
)

job.commit()
