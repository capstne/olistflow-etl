# creates secret in AWS Secrets Manager to store RDS master password
resource "random_password" "rds_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?" # note: no @, no space, no slash, no quote
}

resource "aws_secretsmanager_secret" "rds_password" {
  name                    = "${local.name}-rds-master-password"
  description             = "Master password for olist-etl RDS instance"
  recovery_window_in_days = 7 
}

resource "aws_secretsmanager_secret_version" "rds_password_version" {
  secret_id     = aws_secretsmanager_secret.rds_password.id
  secret_string = random_password.rds_password.result
}