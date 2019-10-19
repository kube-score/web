resource "null_resource" "compile_score" {
  provisioner "local-exec" {
    command     = "mkdir -p files && go build -o files/api-linux-amd64 && zip -r files/api-linux-amd64.zip files/api-linux-amd64"
    working_dir = ".."
    environment = {
      GOOS   = "linux"
      GOARCH = "amd64"
    }
  }

  triggers = {
    src   = filemd5("../main.go")
    gomod = filemd5("../go.mod")
    gosum = filemd5("../go.sum")
  }
}

resource "aws_lambda_function" "kube_score_api" {
  function_name    = "kube_score_api"
  filename         = "../files/api-linux-amd64.zip"
  handler          = "api-linux-amd64"
  source_code_hash = "${filebase64sha256("../files/api-linux-amd64.zip")}"
  role             = aws_iam_role.kube_score_lambda.arn
  runtime          = "go1.x"
  memory_size      = 128
  timeout          = 1

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_role" "kube_score_lambda" {
  name = "kube_score_lambda"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": {
    "Action": "sts:AssumeRole",
    "Principal": {
      "Service": "lambda.amazonaws.com"
    },
    "Effect": "Allow"
  }
}
POLICY

}

resource "aws_lambda_permission" "kube_score_api" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.kube_score_api.arn
  principal     = "apigateway.amazonaws.com"
}
