locals {
  src_dir = "${path.module}/src/"
}

provider "aws" {
  region = var.region
}

# Create IAM User
resource "aws_iam_user" "new_user" {
  name = var.username
}

# Attach ReadOnly permissions to S3 for new_user
resource "aws_iam_user_policy_attachment" "attach_readonly" {
  user       = aws_iam_user.new_user.name
  policy_arn = var.user_policy
}

# Create Access Key for new_user
resource "aws_iam_access_key" "new_user_key" {
  user = aws_iam_user.new_user.name
}

resource "aws_secretsmanager_secret" "new_user_credentials" {
  name        = "${var.username}-aws-credentials"
  description = "AWS access key and secret for ${var.username}"
}

resource "aws_secretsmanager_secret_version" "new_user_credentials_version" {
  secret_id     = aws_secretsmanager_secret.new_user_credentials.id
  secret_string = jsonencode({
    AWS_ACCESS_KEY_ID     = aws_iam_access_key.new_user_key.id
    AWS_SECRET_ACCESS_KEY = aws_iam_access_key.new_user_key.secret
  })
}

# Enable GuardDuty with S3 Protection ONLY
resource "aws_guardduty_detector" "gd" {
  enable = true
  datasources {
    s3_logs {
      enable = true
    }
  }
}

# Create EventBridge Rule for GuardDuty Findings
resource "aws_cloudwatch_event_rule" "gd_kali_finding" {
  name        = var.ev_bridge_r_name
  description = "Trigger Lambda when GuardDuty detects Kali Linux access"
  event_pattern = file("${local.src_dir}${var.pattern_file}")  # Loads event pattern JSON
}

# Lambda IAM Role and Permissions
resource "aws_iam_role" "lambda_exec" {
  name = var.lambda_role_name
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policies" {
  count      = length(var.lambda_policies_arn)
  role       = aws_iam_role.lambda_exec.name
  policy_arn = var.lambda_policies_arn[count.index]
}

# Create Lambda Function to Remove Kali Credentials
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${local.src_dir}${var.lambda_python_file}.py"
  output_path = "${local.src_dir}${var.lambda_python_file}.zip"
}

resource "aws_lambda_function" "remove_kali_creds" {
  function_name    = var.lambda_func_name
  runtime         = "python3.12"
  handler         = "${var.lambda_python_file}.lambda_handler"
  role            = aws_iam_role.lambda_exec.arn
  filename        = data.archive_file.lambda_zip.output_path
  source_code_hash = filebase64sha256(data.archive_file.lambda_zip.output_path)
}


# Attach EventBridge Rule to Lambda Function
resource "aws_cloudwatch_event_target" "eventbridge_to_lambda" {
  rule      = aws_cloudwatch_event_rule.gd_kali_finding.name
  target_id = var.lambda_func_name
  arn       = aws_lambda_function.remove_kali_creds.arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.remove_kali_creds.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.gd_kali_finding.arn
}

# Create S3 Bucket and "info" Folder
resource "aws_s3_bucket" "my_bucket" {
  bucket = var.bucket_name
}

# Upload `Boom.gif` to S3 `info/` Folder
resource "aws_s3_object" "boom_gif" {
  bucket = aws_s3_bucket.my_bucket.id
  key    = "${var.s3_dir_name}${var.file_name}"
  source = "${local.src_dir}${var.file_name}"
  content_type = "image/gif"
}
