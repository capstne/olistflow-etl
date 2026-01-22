# makes glue role datalake admin, adds "ALTER" and "DESCRIBE" lake formation db permissions for provisioned glue dbs 

resource "aws_lakeformation_data_lake_settings" "admin" {
  admins = [
    aws_iam_role.glue_role.arn
  ]
}

resource "aws_lakeformation_permissions" "remove_raw_db_permissions" {
  principal = aws_iam_role.glue_role.arn

  permissions = ["ALTER", "DESCRIBE"]

  database {
    name = aws_glue_catalog_database.raw.name
  }

  depends_on = [
    aws_lakeformation_data_lake_settings.admin,
    aws_glue_catalog_database.raw
  ]
}

resource "aws_lakeformation_permissions" "remove_curated_db_permissions" {
  principal = aws_iam_role.glue_role.arn

  permissions = ["ALTER", "DESCRIBE"]

  database {
    name = aws_glue_catalog_database.curated.name
  }

  depends_on = [
    aws_lakeformation_data_lake_settings.admin,
    aws_glue_catalog_database.curated
  ]
}
