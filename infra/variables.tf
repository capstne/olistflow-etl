variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "project" {
  type    = string
  default = "olistflow-etl"
}

variable "env" {
  type    = string
  default = "dev"
}

variable "tags" {
  type    = map(string)
  default = {}
}