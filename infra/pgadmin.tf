# generates template file for import into pgadmin via s3 bucket

locals {
  pgadmin_servers_json = templatefile("../templates/servers.json.tmpl", {
    server_name    = "RDS Postgres"
    server_host    = aws_db_instance.main.address
    server_port    = aws_db_instance.main.port
    maintenance_db = "postgres"
    db_username    = "postgres"
    ssl_mode       = "require"
  })
}

resource "local_file" "pgadmin_servers" {
  filename = "${path.module}/artifacts/servers.json"
  content  = local.pgadmin_servers_json
}
