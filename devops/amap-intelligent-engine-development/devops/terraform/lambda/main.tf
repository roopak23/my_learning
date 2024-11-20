

resource "aws_iam_policy" "logs_access" {
  name = "${var.prefix}-lambda-policy-logs-write"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "VisualEditor0",
        "Effect" : "Allow",
        "Action" : [
          "logs:CreateLogStream",
          "logs:CreateLogGroup",
          "logs:PutLogEvents"
        ],
        "Resource" : [
          "arn:aws:logs:${var.region}:${var.account_num}:log-group:/aws/lambda/${aws_lambda_function.instance_manager.function_name}",
          "arn:aws:logs:${var.region}:${var.account_num}:log-group:/aws/lambda/${aws_lambda_function.instance_manager.function_name}:log-stream:*"
        ]
      }
    ]
  })
}

resource "aws_iam_policy" "ec2_instances_manage" {
  name = "${var.prefix}-lambda-policy-ec2"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "VisualEditor0",
        "Effect" : "Allow",
        "Action" : [
          "ec2:StartInstances",
          "autoscaling:SetDesiredCapacity",
          "autoscaling:UpdateAutoScalingGroup",
          "ec2:StopInstances"
        ],
        "Resource" : [
          "arn:aws:autoscaling:${var.region}:${var.account_num}:autoScalingGroup:*:autoScalingGroupName/*",
          "arn:aws:ec2:${var.region}:${var.account_num}:instance/*"
        ]
      },
      {
        "Sid" : "VisualEditor1",
        "Effect" : "Allow",
        "Action" : [
          "ec2:DescribeInstances",
          "sns:Publish",
          "ec2:CreateNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DeleteNetworkInterface"
        ],
        "Resource" : "*"
      }
    ]
  })
}


resource "aws_iam_policy" "emr_instance_manage" {
  name = "${var.prefix}-lambda-policy-emr"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "VisualEditor0",
        "Effect" : "Allow",
        "Action" : [
          "elasticmapreduce:ListInstances",
          "elasticmapreduce:TerminateJobFlows"
        ],
        "Resource" : "arn:aws:elasticmapreduce:${var.region}:${var.account_num}:cluster/*"
      },
      {
        "Sid" : "VisualEditor1",
        "Effect" : "Allow",
        "Action" : "elasticmapreduce:ListClusters",
        "Resource" : "*"
      }
    ]
  })
}

resource "aws_iam_role" "lambda_role" {
  name = "${var.prefix}-lambda"

  tags = {
    Name = "${var.prefix}-lambda"
  }

  #   inline_policy {
  #     name = "amap-lambda-policy-dev-01"

  #     policy = jsonencode({
  #     "Version": "2012-10-17",
  #     "Statement": [
  #         {
  #         "Effect": "Allow",
  #         "Action": [
  #             "logs:CreateLogGroup",
  #             "logs:CreateLogStream",
  #             "logs:PutLogEvents"
  #         ],
  #         "Resource": "arn:aws:logs:*:*:*"
  #         },
  #         {
  #         "Effect": "Allow",
  #         "Action": [
  #             "ec2:Start*",
  #             "ec2:Stop*"
  #         ],
  #         "Resource": "*"
  #         }
  #     ]
  #     })
  #   }

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Principal": {
                "Service": "lambda.amazonaws.com"
            },
            "Effect": "Allow",
            "Action": "sts:AssumeRole",
            "Sid": ""
        }
    ]
}
EOF
}


resource "aws_iam_role_policy_attachment" "lambda-attach-logs_access" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.logs_access.arn
  # managed_policy_arns = [, aws_iam_policy.emr_full_access.arn]
}

resource "aws_iam_role_policy_attachment" "lambda-attach-ec2" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.ec2_instances_manage.arn
  # managed_policy_arns = [, aws_iam_policy.emr_full_access.arn]
}

resource "aws_iam_role_policy_attachment" "lambda-attach-emr" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.emr_instance_manage.arn
}


data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda_instance_manager.py"
  output_path = "${var.prefix}-lambda-function.zip"
}

resource "aws_lambda_function" "instance_manager" {
  filename         = "${var.prefix}-lambda-function.zip"
  function_name    = "${var.prefix}-lambda-instance-management"
  role             = aws_iam_role.lambda_role.arn
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  timeout          = 30
  runtime          = "python3.8"
  handler          = "lambda_instance_manager.lambda_handler"

  environment {
    variables = {
      ENVIRONMENT             = "${var.env}",
      ASGs                    = "${var.eks_config.auto_scaling_group_ids}"
      EXCLUDE                 = "",
      FOUNDATION_CAPACITY     = "${var.eks_config.eks_node_foundation_group_des_size}",
      DATA_CAPACITY           = "${var.eks_config.eks_node_data_group_des_size}",
      MANAGEMENT_CAPACITY     = "${var.eks_config.eks_node_management_group_des_size}",
      FOUNDATION_MIN_CAPACITY = "${var.eks_config.eks_node_foundation_group_min_size}",
      DATA_MIN_CAPACITY       = "${var.eks_config.eks_node_data_group_min_size}",
      MANAGEMENT_MIN_CAPACITY = "${var.eks_config.eks_node_management_group_min_size}",
    }
  }
}

resource "aws_cloudwatch_log_group" "loggroup_instance_managment" {
  name              = "/aws/lambda/${aws_lambda_function.instance_manager.function_name}"
  retention_in_days = var.cloudwatch_log_group_retention_in_days
}



resource "aws_lambda_permission" "allow_events_bridge_to_run_lambda" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.instance_manager.function_name
  principal     = "events.amazonaws.com"
}

## schedule env start
resource "aws_cloudwatch_event_rule" "schedule_lambda_rule_start" {
  name                = "${var.prefix}-lambda-instance-schedule-rule-start"
  description         = "Schedule for Lambda instance-managementFunction"
  schedule_expression = var.schedule_start_env
  is_enabled          = true
}

resource "aws_cloudwatch_event_target" "schedule_lambda_target_start" {
  rule  = aws_cloudwatch_event_rule.schedule_lambda_rule_start.name
  arn   = aws_lambda_function.instance_manager.arn
  input = "{\"action\" : \"start\"}"
}




## schedule lamnda stop
resource "aws_cloudwatch_event_rule" "schedule_lambda_rule_stop" {
  name                = "${var.prefix}-lambda-instance-schedule-rule-stop"
  description         = "Schedule for Lambda instance-managementFunction"
  schedule_expression = var.schedule_stop_env
  is_enabled          = true
}

resource "aws_cloudwatch_event_target" "schedule_lambda_target_stop" {
  rule  = aws_cloudwatch_event_rule.schedule_lambda_rule_stop.name
  arn   = aws_lambda_function.instance_manager.arn
  input = "{\"action\" : \"stop\"}"
}



##############################
# monitoring  log lambda
data "archive_file" "lambda_monitoring_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda_monitoring_log.py"
  output_path = "${var.prefix}-lambda-function-monitoring.zip"
}

resource "aws_lambda_function" "lambda_monitoring" {
  filename      = data.archive_file.lambda_monitoring_zip.output_path
  function_name = "${var.prefix}-lambda-monitoring-log"
  role          = aws_iam_role.lambda_role.arn
  timeout       = 30

  tags = {
    Name = "${var.prefix}-lambda-monitoring-log"
  }

  source_code_hash = filesha256(data.archive_file.lambda_monitoring_zip.output_path)
  runtime          = "python3.9"
  handler          = "lambda_monitoring_log.lambda_handler"
  layers           = ["arn:aws:lambda:${var.region}:336392948345:layer:AWSSDKPandas-Python38:5"]

  vpc_config {
    subnet_ids         = var.network_setup.subnet_ids
    security_group_ids = var.network_setup.security_group_ids
  }

  environment {
    variables = {
      ENVIRONMENT   = "SIT",
      BUCKET        = "amap-s3-sit-01",
      ENDPOINT      = "test",
      USERNAME      = "monitoring",
      PASSWORD      = "monitoring",
      SNS_TOPIC_ARN = var.sns_topic_arn
    }
  }
}

##############################
# monitoring report lambda
data "archive_file" "lambda_monitoring_report_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda_monitoring_report.py"
  output_path = "${var.prefix}-function-monitoring-report.zip"
}

resource "aws_lambda_function" "lambda_monitoring_report" {
  filename      = data.archive_file.lambda_monitoring_report_zip.output_path
  function_name = "${var.prefix}-lambda-monitoring-report"
  role          = aws_iam_role.lambda_role.arn
  timeout       = 30

  tags = {
    Name = "${var.prefix}-lambda-monitoring-report"

  }

  source_code_hash = filesha256(data.archive_file.lambda_monitoring_report_zip.output_path)
  runtime          = "python3.9"
  handler          = "lambda_monitoring_report.lambda_handler"
  layers           = ["arn:aws:lambda:${var.region}:336392948345:layer:AWSSDKPandas-Python38:5"]

  vpc_config {
    subnet_ids         = var.network_setup.subnet_ids
    security_group_ids = var.network_setup.security_group_ids
  }

  environment {
    variables = {
      ENVIRONMENT   = "SIT",
      BUCKET        = "amap-s3-sit-01",
      ENDPOINT      = "test",
      USERNAME      = "monitoring",
      PASSWORD      = "monitoring",
      SNS_TOPIC_ARN = var.sns_topic_arn
    }
  }
}
