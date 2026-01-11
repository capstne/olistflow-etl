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

# Load raw tables from Glue Catalog (after crawler).
raw_orders = spark.table(f"{args['RAW_DB']}.olist_orders_dataset")
raw_customers = spark.table(f"{args['RAW_DB']}.olist_customers_dataset")
raw_items = spark.table(f"{args['RAW_DB']}.olist_order_items_dataset")
raw_products = spark.table(f"{args['RAW_DB']}.olist_products_dataset")
raw_payments = spark.table(f"{args['RAW_DB']}.olist_order_payments_dataset")
raw_reviews = spark.table(f"{args['RAW_DB']}.olist_order_reviews_dataset")
raw_sellers = spark.table(f"{args['RAW_DB']}.olist_sellers_dataset")

# Add order_date partition column (parse from order_purchase_timestamp).
raw_orders = raw_orders.withColumn(
    "order_date",
    to_date(col("order_purchase_timestamp"))
)

# Curated orders (fact seed): join customers, items, payments, aggregate.
curated_orders = raw_orders \
    .join(raw_customers, "customer_id", "left") \
    .join(raw_items, "order_id", "left") \
    .join(raw_products, "product_id", "left") \
    .join(raw_payments, "order_id", "left") \
    .join(raw_reviews, "order_id", "left", "coalesce") \
    .join(raw_sellers, raw_items.seller_id == raw_sellers.seller_id, "left") \
    .groupBy("order_id", "order_date") \
    .agg(
        first("customer_id").alias("customer_id"),
        first("customer_unique_id").alias("customer_unique_id"),
        first("customer_zip_code_prefix").alias("customer_zip_code_prefix"),
        first("customer_city").alias("customer_city"),
        first("customer_state").alias("customer_state"),
        sum("price").alias("total_price"),
        sum("freight_value").alias("total_freight"),
        sum("payment_installments").alias("installments"),
        count("payment_sequential").alias("payment_count"),
        first("order_status").alias("order_status"),
        avg("review_score").alias("avg_review_score")
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
        col("avg_review_score").cast(FloatType())
    )

# Write partitioned Parquet (order_date=YYYY-MM-DD).
curated_orders.write \
    .partitionBy("order_date") \
    .mode("overwrite") \
    .parquet(f"s3://{args['CURATED_BUCKET']}/{args['CURATED_PREFIX']}orders/")

# Register as Glue table (manual, or use crawler).
spark.sql(f"""
    CREATE TABLE IF NOT EXISTS `{args['CURATED_DB']}`.`curated_orders`
    USING PARQUET
    PARTITIONED BY (order_date date)
    LOCATION 's3://{args['CURATED_BUCKET']}/{args['CURATED_PREFIX']}orders/'
""")

job.commit()
