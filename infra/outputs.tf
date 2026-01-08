output "raw_bucket" {
  value = aws_s3_bucket.raw.bucket
}

output "curated_bucket" {
  value = aws_s3_bucket.curated.bucket
}

output "artifacts_bucket" {
  value = aws_s3_bucket.artifacts.bucket
}
