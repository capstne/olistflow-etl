# creates free tier RDS Postgres instance with random password from Secrets Manager
data "aws_secretsmanager_secret_version" "rds_password" {
  secret_id = aws_secretsmanager_secret.rds_password.name
  depends_on = [aws_secretsmanager_secret_version.rds_password_version]
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
  password                = data.aws_secretsmanager_secret_version.rds_password.secret_string
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
