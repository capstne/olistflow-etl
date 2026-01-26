# # makes glue role datalake admin, adds "ALTER" and "DESCRIBE" lake formation db permissions for provisioned glue dbs 

# resource "aws_lakeformation_data_lake_settings" "admin" {
#   admins = [
#     aws_iam_role.glue_role.arn
#   ]
# }

# resource "aws_lakeformation_permissions" "raw_db_permissions" {
#   principal = aws_iam_role.glue_role.arn

#   permissions = ["ALL"]

#   database {
#     name = aws_glue_catalog_database.raw.name
#   }

#   depends_on = [
#     aws_lakeformation_data_lake_settings.admin,
#     aws_glue_catalog_database.raw
#   ]
# }

# resource "aws_lakeformation_permissions" "curated_db_permissions" {
#   principal = aws_iam_role.glue_role.arn

#   permissions = ["ALL"]

#   database {
#     name = aws_glue_catalog_database.curated.name
#   }

#   depends_on = [
#     aws_lakeformation_data_lake_settings.admin,
#     aws_glue_catalog_database.curated
#   ]
# }

data "aws_caller_identity" "current" {}

data "aws_lakeformation_data_lake_settings" "current" {
  catalog_id = data.aws_caller_identity.current.account_id
}

locals {
  lf_admins = distinct(concat(
    data.aws_lakeformation_data_lake_settings.current.admins,
    [aws_iam_role.glue_role.arn]
  ))
}

resource "aws_lakeformation_data_lake_settings" "this" {
  catalog_id = data.aws_caller_identity.current.account_id
  admins     = local.lf_admins

  create_database_default_permissions {}
  create_table_default_permissions  {}

  trusted_resource_owners = data.aws_lakeformation_data_lake_settings.current.trusted_resource_owners
}
