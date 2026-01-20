# creates S3 buckets for raw, curated and artifacts data which versioning and server-side encryption enabled - added necessary S3 objects for initial data and Glue jobs

locals {
  olist_raw_files  = fileset("${path.root}/../data/olist", "**")
  glue_jobs_files  = fileset("${path.root}/../glue/jobs", "**")
  sql_script_files = fileset("${path.root}/../scripts/sql", "**")
}

resource "aws_s3_bucket" "raw" {
  bucket        = "${local.name}-raw"
  force_destroy = true
  tags          = local.tags
}

resource "aws_s3_bucket" "curated" {
  bucket        = "${local.name}-curated"
  force_destroy = true
  tags          = local.tags
}

resource "aws_s3_bucket" "artifacts" {
  bucket        = "${local.name}-artifacts"
  force_destroy = true
  tags          = local.tags
}

resource "aws_s3_bucket_versioning" "raw" {
  bucket = aws_s3_bucket.raw.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_versioning" "curated" {
  bucket = aws_s3_bucket.curated.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_versioning" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "raw" {
  bucket = aws_s3_bucket.raw.id
  rule {
    apply_server_side_encryption_by_default { sse_algorithm = "AES256" }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "curated" {
  bucket = aws_s3_bucket.curated.id
  rule {
    apply_server_side_encryption_by_default { sse_algorithm = "AES256" }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id
  rule {
    apply_server_side_encryption_by_default { sse_algorithm = "AES256" }
  }
}

resource "aws_s3_object" "add_raw_files" {
  for_each = local.olist_raw_files

  bucket      = aws_s3_bucket.raw.id
  key         = "${var.raw_prefix}${each.value}"
  source      = "${path.root}/../data/${var.raw_prefix}${each.value}"
  source_hash = filemd5("${path.root}/../data/${var.raw_prefix}${each.value}")
  tags        = local.tags
}

resource "aws_s3_object" "add_glue_jobs_files" {
  for_each = local.glue_jobs_files

  bucket      = aws_s3_bucket.artifacts.id
  key         = "${var.glue_jobs_prefix}${each.value}"
  source      = "${path.root}/../${var.glue_jobs_prefix}${each.value}"
  source_hash = filemd5("${path.root}/../${var.glue_jobs_prefix}${each.value}")
  tags        = local.tags
}

resource "aws_s3_object" "add_sql_script" {
  for_each = local.sql_script_files

  bucket      = aws_s3_bucket.artifacts.id
  key         = "${var.sql_scripts_prefix}${each.value}"
  source      = "${path.root}/../${var.sql_scripts_prefix}${each.value}"
  source_hash = filemd5("${path.root}/../${var.sql_scripts_prefix}${each.value}")
  tags        = local.tags
}

resource "aws_s3_object" "add_pgadmin_servers_connection_details" {
  bucket = aws_s3_bucket.artifacts.id
  key    = "pgadmin/servers.json"

  content      = local.pgadmin_servers_json
  content_type = "application/json"
}