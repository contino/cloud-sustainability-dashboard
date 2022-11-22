output "database_name" {
  value = aws_glue_catalog_database.aws_glue_catalog_database.name
}

output "database_arn" {
  value = aws_glue_catalog_database.aws_glue_catalog_database.arn
}

output "data_table_name" {
  value = aws_glue_catalog_table.aws_glue_catalog_table.name
}

output "data_table_arn" {
  value = aws_glue_catalog_table.aws_glue_catalog_table.arn
}

output "status_table_name" {
  value = "cost_and_usage_data_status"
}
