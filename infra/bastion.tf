# bastion.tf - Minimal Windows Bastion EC2 for RDS access 

resource "aws_security_group" "bastion" {
  name_prefix = "bastion-windows-"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 3389 # RDP
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    # cidr_blocks = ["99.241.135.123/32", "129.41.87.2/32"] # if not Temi, replace with your laptop's public IP
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
  iam_instance_profile        = aws_iam_instance_profile.bastion_profile.name

  root_block_device {
    volume_size = 30 # Windows minimum
    volume_type = "gp3"
  }

  user_data = templatefile("../scripts/windows/windows-userdata.ps1", {
    db_host     = aws_db_instance.main.address
    db_port     = aws_db_instance.main.port
    db_name     = var.db_name
    db_username = var.db_username
    db_password = random_password.rds_password.result
    }
  )

  tags = {
    Name = "windows-bastion-rds"
  }

  lifecycle {
    ignore_changes = [ami] # Windows AMIs update often
  }

  depends_on = [aws_db_instance.main, aws_s3_object.add_glue_jobs_files, aws_s3_object.add_pgadmin_servers_connection_details, aws_s3_object.add_sql_script]
}

data "aws_ami" "windows" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["Windows_Server-2022-English-Full-Base-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}