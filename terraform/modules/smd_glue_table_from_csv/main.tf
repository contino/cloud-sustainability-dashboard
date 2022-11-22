resource "aws_glue_catalog_table" "this" {
  name          = var.glue_table_name
  database_name = var.glue_database_name
  table_type    = "EXTERNAL_TABLE"

  parameters = {
    EXTERNAL                 = "TRUE"
    "skip.header.line.count" = "1"
  }

  storage_descriptor {
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"

    ser_de_info {
      serialization_library = "org.apache.hadoop.hive.serde2.lazy.LazySimpleSerDe"

      parameters = {
        "serialization.format" = ","
        "field.delim"          = ","
      }
    }

    location = var.s3_table_location

    dynamic "columns" {
      for_each = var.columns
      content {
        name = columns.value["name"]
        type = columns.value["type"]
      }
    }
  }
}

resource "aws_s3_object" "this" {
  count       = length(var.csv_files)
  bucket      = var.s3_bucket_name
  key         = var.csv_files[count.index].s3_key
  source      = var.csv_files[count.index].local_path
  source_hash = filemd5(var.csv_files[count.index].local_path)
}
