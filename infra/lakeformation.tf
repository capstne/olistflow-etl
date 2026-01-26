resource "aws_lakeformation_data_lake_settings" "this" {
  catalog_id = data.aws_caller_identity.current.account_id

  create_database_default_permissions {}
  create_table_default_permissions  {}
}

