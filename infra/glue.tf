# creates glue catalog databases, crawlers and jobs
resource "aws_glue_catalog_database" "raw" {
  name = replace("${var.project}_raw", "-", "_")
  tags = local.tags
}

resource "aws_glue_catalog_database" "curated" {
  name = replace("${var.project}_curated", "-", "_")
  tags = local.tags
}

resource "aws_glue_crawler" "raw" {
  name          = replace("${local.name}-raw-crawler", "-", "_")
  role          = aws_iam_role.glue_role.arn
  database_name = aws_glue_catalog_database.raw.name
  classifiers    = [aws_glue_classifier.csv_olist.id]
  tags          = local.tags

  s3_target {
    path = "s3://${aws_s3_bucket.raw.bucket}/${var.raw_prefix}"
  }

  schema_change_policy {
    delete_behavior = "LOG"
    update_behavior = "UPDATE_IN_DATABASE"
  }
}

resource "aws_glue_classifier" "csv_olist" {
  name = replace("${local.name}-csv-classifier", "-", "_")

  csv_classifier {
    delimiter        = ","
    quote_symbol     = "\""
    contains_header  = "PRESENT"
    disable_value_trimming = false
  }
}

resource "aws_glue_job" "raw_to_curated" {
  name     = replace("${local.name}-raw-to-curated", "-", "_")
  role_arn = aws_iam_role.glue_role.arn
  tags     = local.tags

  glue_version      = "4.0"
  number_of_workers = 2
  worker_type       = "G.1X"
  timeout           = 30  

  command {
    name            = "glueetl"
    python_version  = "3"
    script_location = "s3://${aws_s3_bucket.artifacts.bucket}/${var.glue_jobs_prefix}${var.glue_script_raw_to_curated_key}"
  }

  default_arguments = {
    "--job-language" = "python"

    "--RAW_BUCKET"     = aws_s3_bucket.raw.bucket
    "--CURATED_BUCKET" = aws_s3_bucket.curated.bucket
    "--RAW_PREFIX"     = var.raw_prefix
    "--CURATED_PREFIX" = var.curated_prefix

    "--RAW_DB"     = aws_glue_catalog_database.raw.name
    "--CURATED_DB" = aws_glue_catalog_database.curated.name

    "--enable-metrics"                   = ""
    "--enable-continuous-cloudwatch-log" = "true"
  }
}

resource "aws_glue_job" "curated_to_rds" {
  name     = replace("${local.name}-curated-to-rds", "-", "_")
  role_arn = aws_iam_role.glue_role.arn
  tags     = local.tags

  glue_version      = "4.0"
  number_of_workers = 2
  worker_type       = "G.1X"
  timeout           = 30

  command {
    name            = "glueetl"
    python_version  = "3"
    script_location = "s3://${aws_s3_bucket.artifacts.bucket}/${var.glue_jobs_prefix}${var.glue_script_curated_to_rds_key}"
  }

  default_arguments = {
    "--job-language" = "python"

    "--CURATED_BUCKET"                   = aws_s3_bucket.curated.bucket
    "--CURATED_PREFIX"                   = var.curated_prefix
    "--CURATED_DB"                       = aws_glue_catalog_database.curated.name
    "--JDBC_CONNECTION_NAME"             = aws_glue_connection.rds.name
    "--enable-metrics"                   = ""
    "--enable-continuous-cloudwatch-log" = "true"
  }
}
