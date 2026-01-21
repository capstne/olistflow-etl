# S3 Gateway VPC Endpoint (REQUIRED for Glue in private subnets)
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.us-east-1.s3"
  vpc_endpoint_type = "Gateway"
  auto_accept       = true

  tags = merge(local.tags, { Name = "${local.name}-s3-endpoint" })
}