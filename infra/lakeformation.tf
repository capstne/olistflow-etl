data "aws_lakeformation_data_lake_settings" "current" {
  catalog_id = data.aws_caller_identity.current.account_id
}

resource "aws_lakeformation_data_lake_settings" "this" {
  catalog_id = data.aws_caller_identity.current.account_id
  admins     = ["arn:aws:iam::916740064153:user/user.temi.oluseun"]


  create_database_default_permissions {}
  create_table_default_permissions  {}
}

