provider "aws" {
  region = "ap-south-1"
}

resource "aws_lambda_function" "notification_function" {
  filename         = "lambda_function.zip"
  function_name    = "notification_function"
  role             = aws_iam_role.lambda_execution.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.8"
  memory_size      = 128
  timeout          = 60
  publish          = true
  source_code_hash = filebase64sha256("lambda_function.zip")

  environment {
    variables = {
     SNS_TOPIC_ARN = aws_sns_topic.notification_topic.arn
   
    
    }
  }
}

data "archive_file" "lambda_function" {
  type        = "zip"
  source_dir = "lambda_function"

  output_path = "lambda_function.zip"
}

resource "aws_iam_role" "lambda_execution" {
  name = "lambda_execution"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_execution_policy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.lambda_execution.name
}
resource "aws_iam_role_policy_attachment" "lambda_sns_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSNSFullAccess"
  role       = aws_iam_role.lambda_execution.name
}
resource "aws_iam_role_policy_attachment" "lambda_cloudwatch_policy" {
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchEventsFullAccess"
  role       = aws_iam_role.lambda_execution.name
}
resource "aws_iam_role_policy_attachment" "lambda_cloudtrail_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AWSCloudTrail_FullAccess"
  role       = aws_iam_role.lambda_execution.name
}

resource "aws_cloudwatch_event_rule" "resource_change_event" {
  name        = "resource_change_event"
  description = "Event rule to detect changes to AWS resources"
  event_pattern = <<EOF
{
  "source": ["aws.ec2"],
  "detail-type": ["AWS API Call via CloudTrail"],
  "detail": {
    "eventSource": ["ec2.amazonaws.com"],
    "eventName": ["CreateVpc", "RunInstance", "StopInstances", "StartInstance", "DeleteVpc"]
  }
}
EOF
}

resource "aws_cloudwatch_event_target" "invoke_notification_lambda" {
  rule      = aws_cloudwatch_event_rule.resource_change_event.name
  target_id = "invoke_notification_lambda"
  arn       = aws_lambda_function.notification_function.arn
}

resource "aws_sns_topic" "notification_topic" {
  name = "notification_topic"
}

# data "aws_sns_topic" "notification_topicdata" {
#   name = "notification_topic"
# }

resource "aws_lambda_permission" "allow_cloudwatch_to_invoke_notification_lambda" {
  statement_id  = "AllowExecutionFromCloudWatchEvents"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.notification_function.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.resource_change_event.arn
}

resource "aws_sns_topic_subscription" "subscribe_email_to_notification_topic" {
  topic_arn = aws_sns_topic.notification_topic.arn
  protocol  = "email"
  endpoint  = "yaditya308@gmail.com"
}
