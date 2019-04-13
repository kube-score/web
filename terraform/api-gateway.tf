resource "aws_api_gateway_rest_api" "kube_score_api" {
  name = "kube_score_api"
}

resource "aws_api_gateway_domain_name" "api_kube_score_com" {
  certificate_arn = "arn:aws:acm:us-east-1:414416641486:certificate/bd748af3-d789-4c58-8108-79b707b7ba02"
  domain_name     = "api.kube-score.com"
}

resource "aws_api_gateway_base_path_mapping" "api_kube_score_com" {
  api_id      = "${aws_api_gateway_rest_api.kube_score_api.id}"
  stage_name  = "${aws_api_gateway_deployment.kube_score_api_v1.stage_name}"
  domain_name = "${aws_api_gateway_domain_name.api_kube_score_com.domain_name}"
}

resource "aws_api_gateway_resource" "score" {
  rest_api_id = "${aws_api_gateway_rest_api.kube_score_api.id}"
  parent_id   = "${aws_api_gateway_rest_api.kube_score_api.root_resource_id}"
  path_part   = "score"
}

resource "aws_api_gateway_method" "post_score" {
  rest_api_id   = "${aws_api_gateway_rest_api.kube_score_api.id}"
  resource_id   = "${aws_api_gateway_resource.score.id}"
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "kube_score_api" {
  rest_api_id             = "${aws_api_gateway_rest_api.kube_score_api.id}"
  resource_id             = "${aws_api_gateway_resource.score.id}"
  http_method             = "${aws_api_gateway_method.post_score.http_method}"
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:${data.aws_region.current.name}:lambda:path/2015-03-31/functions/${aws_lambda_function.kube_score_api.arn}/invocations"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_deployment" "kube_score_api_v1" {
  depends_on = [
    "aws_api_gateway_integration.kube_score_api",
  ]

  # Automatically trigger a deployment if the api has changed
  stage_description = <<DESCRIPTION
${aws_api_gateway_resource.score.id}
${aws_api_gateway_method.post_score.id}
${aws_api_gateway_integration.kube_score_api.id}
${aws_api_gateway_method.options_method.id}
${aws_api_gateway_integration.options_integration.id}
DESCRIPTION

  rest_api_id = "${aws_api_gateway_rest_api.kube_score_api.id}"
  stage_name  = "v1"

  lifecycle {
    create_before_destroy = true
  }
}

output "url" {
  value = "${aws_api_gateway_deployment.kube_score_api_v1.invoke_url}${aws_api_gateway_resource.score.path}"
}
