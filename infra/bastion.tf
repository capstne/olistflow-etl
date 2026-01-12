# bastion.tf - Minimal Windows Bastion EC2 for RDS access 

data "aws_secretsmanager_secret_version" "ec2_password" {
  secret_id  = aws_secretsmanager_secret.ec2_password.name
  depends_on = [aws_secretsmanager_secret_version.ec2_password_version]
}

resource "aws_security_group" "bastion" {
  name_prefix = "bastion-windows-"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 3389 # RDP
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["99.241.135.123/32"] # if not Temi, replace with your laptop's public IP
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "rds_access" {
  type                     = "ingress"
  from_port                = 5432 # PostgreSQL
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = aws_security_group.rds.id
  source_security_group_id = aws_security_group.bastion.id
}

resource "tls_private_key" "bastion" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "bastion" {
  key_name   = "${local.name}-bastion-key"
  public_key = tls_private_key.bastion.public_key_openssh
}

resource "aws_instance" "bastion" {
  ami                         = data.aws_ami.windows.id
  instance_type               = "t3.medium"
  subnet_id                   = aws_subnet.public[0].id
  vpc_security_group_ids      = [aws_security_group.bastion.id]
  associate_public_ip_address = true
  key_name                    = aws_key_pair.bastion.key_name

  root_block_device {
    volume_size = 30 # Windows minimum
    volume_type = "gp3"
  }

  user_data = base64encode(templatefile("../scripts/windows/windows-userdata.ps1", {
    admin_password = data.aws_secretsmanager_secret_version.ec2_password.secret_string
  }))

  tags = {
    Name = "windows-bastion-rds"
  }

  lifecycle {
    ignore_changes = [ami] # Windows AMIs update often
  }
}

data "aws_ami" "windows" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["Windows_Server-2022-English-Full-Base-*"] # ARM for t4g.nano
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}