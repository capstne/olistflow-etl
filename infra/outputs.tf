output "raw_bucket" {
  value = aws_s3_bucket.raw.bucket
}

output "curated_bucket" {
  value = aws_s3_bucket.curated.bucket
}

output "artifacts_bucket" {
  value = aws_s3_bucket.artifacts.bucket
}

output "glue_raw_db" {
  value = aws_glue_catalog_database.raw.name
}

output "glue_curated_db" {
  value = aws_glue_catalog_database.curated.name
}

output "rds_password" {
  value       = random_password.rds_password.result
  description = "RDS password (rotate/delete after use)"
  sensitive   = true
}

output "rds_endpoint" {
  value = aws_db_instance.main.endpoint
}