# added Step Functions State Machine for ETL orchestration

resource "aws_sfn_state_machine" "etl" {
  name     = "${local.name}-orchestrator"
  role_arn = aws_iam_role.sfn_role.arn
  tags     = local.tags
  type     = "STANDARD"

  definition = templatefile("${path.module}/stepfunctions/olistflow_etl.asl.json.tpl", {
    crawler_name       = aws_glue_crawler.raw.name
    raw_to_curated_job = aws_glue_job.raw_to_curated.name
    curated_to_rds_job = aws_glue_job.curated_to_rds.name
  })
}
