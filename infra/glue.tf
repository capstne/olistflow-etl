resource "aws_glue_catalog_database" "raw" {
  name = "${var.project}_raw"
  tags = local.tags
}

resource "aws_glue_catalog_database" "curated" {
  name = "${var.project}_curated"
  tags = local.tags
}

resource "aws_glue_crawler" "raw" {
  name          = "${local.name}-raw-crawler"
  role          = aws_iam_role.glue_role.arn
  database_name = aws_glue_catalog_database.raw.name
  tags          = local.tags

  s3_target {
    path = "s3://${aws_s3_bucket.raw.bucket}/${var.raw_prefix}"
  }

  schema_change_policy {
    delete_behavior = "LOG"
    update_behavior = "UPDATE_IN_DATABASE"
  }
}

resource "aws_glue_job" "raw_to_curated" {
  name     = "${local.name}-raw-to-curated"
  role_arn = aws_iam_role.glue_role.arn
  tags     = local.tags

  glue_version      = "4.0"
  number_of_workers = 2
  worker_type       = "G.1X"
  timeout           = 30

  command {
    name            = "glueetl"
    python_version  = "3"
    script_location = "s3://${aws_s3_bucket.artifacts.bucket}/${var.glue_script_raw_to_curated_key}"
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
  name     = "${local.name}-curated-to-rds"
  role_arn = aws_iam_role.glue_role.arn
  tags     = local.tags

  glue_version      = "4.0"
  number_of_workers = 2
  worker_type       = "G.1X"
  timeout           = 30

  command {
    name            = "glueetl"
    python_version  = "3"
    script_location = "s3://${aws_s3_bucket.artifacts.bucket}/${var.glue_script_curated_to_rds_key}"
  }

  default_arguments = {
    "--job-language" = "python"

    "--CURATED_BUCKET"       = aws_s3_bucket.curated.bucket
    "--CURATED_PREFIX"       = var.curated_prefix
    "--CURATED_DB"           = aws_glue_catalog_database.curated.name
    "--JDBC_CONNECTION_NAME" = aws_glue_connection.rds.name

    # RDS parameters will be wired later (JDBC URL / secrets / connection).
    "--RDS_JDBC_URL" = ""
    "--RDS_USER"     = ""
    "--RDS_PASSWORD" = ""

    "--enable-metrics"                   = ""
    "--enable-continuous-cloudwatch-log" = "true"
  }
}
