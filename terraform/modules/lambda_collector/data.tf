data "archive_file" "this" {
  type        = "zip"
  source_dir  = var.path
  output_path = "${path.root}/lambda.zip"
}

data "aws_iam_policy_document" "lambda_execution_role_trust_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}