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

# Curated orders (fact seed): join customers, items, payments, aggregate.
curated_orders = raw_orders_df \
    .join(raw_customers_df, "customer_id", "left") \
    .join(raw_items_df, "order_id", "left") \
    .join(raw_products_df, "product_id", "left") \
    .join(raw_payments_df, "order_id", "left") \
    .join(raw_reviews_df, "order_id", "left", "coalesce") \
    .join(raw_sellers_df, raw_items_df["seller_id"] == raw_sellers_df["seller_id"], "left") \
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

job.commit()
