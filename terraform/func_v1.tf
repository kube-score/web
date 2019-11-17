resource "aws_api_gateway_resource" "score" {
  rest_api_id = aws_api_gateway_rest_api.kube_score_api.id
  parent_id   = aws_api_gateway_rest_api.kube_score_api.root_resource_id
  path_part   = "score"
}

resource "aws_api_gateway_method" "post_score" {
  rest_api_id   = aws_api_gateway_rest_api.kube_score_api.id
  resource_id   = aws_api_gateway_resource.score.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "kube_score_api" {
  rest_api_id             = aws_api_gateway_rest_api.kube_score_api.id
  resource_id             = aws_api_gateway_resource.score.id
  http_method             = aws_api_gateway_method.post_score.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:${data.aws_region.current.name}:lambda:path/2015-03-31/functions/${aws_lambda_function.kube_score_api.arn}/invocations"

  lifecycle {
    create_before_destroy = true
  }
}
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

resource "aws_lambda_permission" "kube_score_api" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.kube_score_api.arn
  principal     = "apigateway.amazonaws.com"
}

resource "aws_api_gateway_method" "options_method" {
  rest_api_id   = aws_api_gateway_rest_api.kube_score_api.id
  resource_id   = aws_api_gateway_resource.score.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_method_response" "options_200" {
  rest_api_id = aws_api_gateway_rest_api.kube_score_api.id
  resource_id = aws_api_gateway_resource.score.id
  http_method = aws_api_gateway_method.options_method.http_method
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }

  depends_on = [aws_api_gateway_method.options_method]
}

resource "aws_api_gateway_integration" "options_integration" {
  rest_api_id = aws_api_gateway_rest_api.kube_score_api.id
  resource_id = aws_api_gateway_resource.score.id
  http_method = aws_api_gateway_method.options_method.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }

  depends_on = [aws_api_gateway_method.options_method]
}

resource "aws_api_gateway_integration_response" "options_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.kube_score_api.id
  resource_id = aws_api_gateway_resource.score.id
  http_method = aws_api_gateway_method.options_method.http_method
  status_code = aws_api_gateway_method_response.options_200.status_code

  response_templates = {
    "application/json" = ""
  }

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
    "method.response.header.Access-Control-Allow-Methods" = "'POST,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }

  depends_on = [aws_api_gateway_method_response.options_200]
}
