# removes all lake formation db permissions for provisioned glue dbs 
resource "aws_lakeformation_permissions" "remove_raw_db_permissions" {
  principal = aws_iam_role.glue_role.arn

  permissions = []  # empty = removes all LF permissions

  database {
    name = aws_glue_catalog_database.raw.name
  }
}

resource "aws_lakeformation_permissions" "remove_curated_db_permissions" {
  principal = aws_iam_role.glue_role.arn

  permissions = []  # empty = removes all LF permissions

  database {
    name = aws_glue_catalog_database.curated.name
  }
}
