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

# Glue job scripts are expected to be uploaded to the artifacts bucket at these keys.
variable "glue_script_raw_to_curated_key" {
  type    = string
  default = "glue/jobs/raw_to_curated.py"
}

variable "glue_script_curated_to_rds_key" {
  type    = string
  default = "glue/jobs/curated_to_rds.py"
}

# Change if you want different crawler targets/prefixing.
variable "raw_prefix" {
  type    = string
  default = "olist/"
}

variable "curated_prefix" {
  type    = string
  default = "olist/"
}