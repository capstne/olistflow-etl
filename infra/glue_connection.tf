# creates jdbc glue connection to rds instance
resource "aws_glue_connection" "rds" {
  name = replace("${local.name}-rds-jdbc", "-", "_")

  connection_properties = {
    JDBC_CONNECTION_URL = "jdbc:postgresql://${aws_db_instance.main.endpoint}/postgres?sslmode=require"
    USERNAME            = "postgres"
    PASSWORD            = random_password.rds_password.result
  }

  physical_connection_requirements {
    availability_zone      = data.aws_availability_zones.available.names[0]
    security_group_id_list = [aws_security_group.rds.id, aws_security_group.glue.id]
    subnet_id              = aws_subnet.private[0].id
  }
}
