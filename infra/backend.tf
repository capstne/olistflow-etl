terraform {
  backend "s3" {
    bucket = "olistflow-terraform-state"
    key    = "olistflow-etl/terraform.tfstate"
    region = "us-east-1"
  }
}