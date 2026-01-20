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

variable "glue_jobs_prefix" {
  type    = string
  default = "glue/jobs/"
}

variable "glue_script_raw_to_curated_key" {
  type    = string
  default = "raw_to_curated.py"
}

variable "glue_script_curated_to_rds_key" {
  type    = string
  default = "curated_to_rds.py"
}

variable "raw_prefix" {
  type    = string
  default = "olist/"
}

variable "curated_prefix" {
  type    = string
  default = "olist/"
}

variable "sql_scripts_prefix" {
  type    = string
  default = "scripts/sql/"
}