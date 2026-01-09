resource "random_password" "rds_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?" # note: no @, no space, no slash, no quote
}

resource "aws_db_instance" "main" {
  identifier              = local.name
  instance_class          = "db.t4g.micro"
  allocated_storage       = 20
  max_allocated_storage   = 100
  engine                  = "postgres"
  engine_version          = "16"
  storage_encrypted       = true
  db_subnet_group_name    = aws_db_subnet_group.main.name
  vpc_security_group_ids  = [aws_security_group.rds.id]
  username                = "postgres"
  password                = random_password.rds_password.result
  skip_final_snapshot     = true
  backup_retention_period = 1
  multi_az                = false
  tags                    = local.tags
}

resource "aws_db_subnet_group" "main" {
  name       = local.name
  subnet_ids = aws_subnet.private[*].id
  tags       = local.tags
}

# Output the password temporarily (rotate in prod).
output "rds_password" {
  value       = random_password.rds_password.result
  description = "RDS password (rotate/delete after use)"
  sensitive   = true
}

output "rds_endpoint" {
  value = aws_db_instance.main.endpoint
}
