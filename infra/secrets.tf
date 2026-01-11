# creates secret in AWS Secrets Manager to store RDS master password, EC2 admin password and bastion key pair

resource "random_password" "rds_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?" # note: no @, no space, no slash, no quote
}

resource "aws_secretsmanager_secret" "rds_password" {
  name                    = "${local.name}-rds-master-password"
  description             = "Master password for olist-etl RDS instance"
}

resource "aws_secretsmanager_secret_version" "rds_password_version" {
  secret_id     = aws_secretsmanager_secret.rds_password.id
  secret_string = random_password.rds_password.result
}

resource "random_password" "ec2_admin_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?" # note: no @, no space, no slash, no quote
}

resource "aws_secretsmanager_secret" "ec2_password" {
  name                    = "${local.name}-ec2-master-password"
  description             = "Master password for olist-etl EC2 instance"
}

resource "aws_secretsmanager_secret_version" "ec2_password_version" {
  secret_id     = aws_secretsmanager_secret.ec2_password.id
  secret_string = random_password.ec2_admin_password.result
}

resource "aws_secretsmanager_secret" "bastion_keypair" {
  name                    = "${local.name}-bastion-keypair"
  description             = "SSH key pair for bastion host (private + public)"
  tags = {
    Name = "bastion-keypair"
  }
}

resource "aws_secretsmanager_secret_version" "bastion_keypair" {
  secret_id     = aws_secretsmanager_secret.bastion_keypair.id
  secret_string = jsonencode({
    private_key_pem = tls_private_key.bastion.private_key_pem
    public_key_ssh  = tls_private_key.bastion.public_key_openssh
  })
}