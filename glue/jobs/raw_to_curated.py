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
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args['JOB_NAME'], args)

# Debug: SHOW DATABASES will only list 'default' - normal for raw Spark SQL
print(spark.catalog.currentDatabase())
spark.sql("SHOW DATABASES").show()

# Load via GlueContext (bypasses Spark catalog issues)
raw_orders_df = glueContext.create_dynamic_frame.from_catalog(
    database=args['RAW_DB'],
    table_name="olist_orders_dataset_csv"
).toDF()

raw_customers_df = glueContext.create_dynamic_frame.from_catalog(
    database=args['RAW_DB'],
    table_name="olist_customers_dataset_csv"
).toDF()

raw_items_df = glueContext.create_dynamic_frame.from_catalog(
    database=args['RAW_DB'],
    table_name="olist_order_items_dataset_csv"
).toDF()

raw_products_df = glueContext.create_dynamic_frame.from_catalog(
    database=args['RAW_DB'],
    table_name="olist_products_dataset_csv"
).toDF()

raw_payments_df = glueContext.create_dynamic_frame.from_catalog(
    database=args['RAW_DB'],
    table_name="olist_order_payments_dataset_csv"
).toDF()

raw_reviews_df = glueContext.create_dynamic_frame.from_catalog(
    database=args['RAW_DB'],
    table_name="olist_order_reviews_dataset_csv"
).toDF()

raw_sellers_df = glueContext.create_dynamic_frame.from_catalog(
    database=args['RAW_DB'],
    table_name="olist_sellers_dataset_csv"
).toDF()

# Add order_date partition column (parse from order_purchase_timestamp).
raw_orders_df = raw_orders_df.withColumn(
    "order_date",
    to_date(col("order_purchase_timestamp"))
)

raw_sellers_df = raw_sellers_df.withColumnRenamed("seller_id", "raw_seller_id")

# Curated orders (fact seed): join customers, items, products, payments, reviews, sellers, aggregate.
temp_joined = raw_orders_df \
    .join(raw_customers_df, "customer_id", "left") \
    .join(raw_items_df, "order_id", "left") \
    .join(raw_products_df, "product_id", "left") \
    .join(raw_payments_df, "order_id", "left") \
    .join(raw_reviews_df, "order_id", "left") \
    .join(raw_sellers_df, col("seller_id") == raw_sellers_df["raw_seller_id"], "left") 

# Minimal groupBy: order_id + order_date, pick first of each (validates joins work).
curated_orders = temp_joined \
    .groupBy("order_id", "order_date") \
    .agg(
        first("customer_id").alias("customer_id"),
        first("customer_unique_id").alias("customer_unique_id"),
        first("customer_zip_code_prefix").alias("customer_zip_code_prefix"),
        first("customer_city").alias("customer_city"),
        first("customer_state").alias("customer_state"),
        first("price").alias("sample_price"),  # Test sum later
        first("freight_value").alias("sample_freight"),
        first("payment_installments").alias("sample_installments"),
        first("payment_sequential").alias("sample_payment_seq"),
        first("order_status").alias("order_status"),
        first("review_score").alias("sample_review_score")
    ) \
    .select(
        col("order_id"),
        col("order_date").cast(DateType()),
        col("customer_id"),
        col("customer_unique_id"),
        col("customer_zip_code_prefix").cast(IntegerType()),
        col("customer_city"),
        col("customer_state"),
        col("sample_price").cast(DoubleType()),
        col("sample_freight").cast(DoubleType()),
        col("sample_installments").cast(IntegerType()),
        col("sample_payment_seq").cast(IntegerType()),
        col("order_status"),
        col("sample_review_score").cast(FloatType())
    )

wr.catalog.create_database(args['CURATED_DB'], exist_ok=True)

# Define schema manually from printSchema() output
columns_types = {
    "order_id": "string",
    "customer_id": "string",
    "customer_unique_id": "string",
    "customer_zip_code_prefix": "int",
    "customer_city": "string",
    "customer_state": "string",
    "sample_price": "double",
    "sample_freight": "double",
    "sample_installments": "int",
    "sample_payment_seq": "int",
    "order_status": "string",
    "sample_review_score": "float"
}

# # infer columns_types from 1st row
# sample_pd = curated_orders.limit(1).toPandas()  # Small sample for inference
# columns_types = wr.catalog.extract_athena_types(sample_pd)[0] 

partitions_types = {"order_date": "date"}

wr.catalog.create_parquet_table(
    database=args['CURATED_DB'],
    table="orders",
    path=f"s3://{args['CURATED_BUCKET']}/{args['CURATED_PREFIX']}orders/",
    columns_types=columns_types,
    partitions_types=partitions_types,
    mode="overwrite"
)
job.commit()
