resource "aws_lambda_function" "function" {
  function_name    = "kube_score_api_${var.name}"
  filename         = "${var.root}/files/${var.name}-linux-amd64.zip"
  handler          = "${var.name}-linux-amd64"
  source_code_hash = filebase64sha256("${var.root}/files/${var.name}-linux-amd64.zip")
  role             = var.aws_iam_role_arn
  runtime          = "go1.x"
  memory_size      = 128
  timeout          = 1

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lambda_permission" "invoke_func" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.function.arn
  principal     = "apigateway.amazonaws.com"
}

resource "aws_api_gateway_resource" "resource" {
  rest_api_id = var.rest_api_id
  parent_id   = var.rest_api_parent_id
  path_part   = var.name
}

resource "aws_api_gateway_method" "post" {
  rest_api_id   = var.rest_api_id
  resource_id   = aws_api_gateway_resource.resource.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "integration" {
  rest_api_id             = var.rest_api_id
  resource_id             = aws_api_gateway_resource.resource.id
  http_method             = aws_api_gateway_method.post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:${var.aws_region_name}:lambda:path/2015-03-31/functions/${aws_lambda_function.function.arn}/invocations"

  lifecycle {
    create_before_destroy = true
  }
}
