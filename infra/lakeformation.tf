data "aws_lakeformation_data_lake_settings" "current" {
  catalog_id = data.aws_caller_identity.current.account_id
}

locals {
  existing_admins = [
    for a in tolist(data.aws_lakeformation_data_lake_settings.current.admins) :
    a if can(regex("^arn:", a))
  ]

  # lf_admins = distinct(concat(
  #   local.existing_admins,
  #   [aws_iam_role.glue_role.arn]
  # ))
}

resource "aws_lakeformation_data_lake_settings" "this" {
  catalog_id = data.aws_caller_identity.current.account_id
  admins     = local.existing_admins

  create_database_default_permissions {}
  create_table_default_permissions  {}

  trusted_resource_owners = data.aws_lakeformation_data_lake_settings.current.trusted_resource_owners
}

