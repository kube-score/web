resource "aws_api_gateway_rest_api" "kube_score_api" {
  name = "kube_score_api"
}

resource "aws_api_gateway_domain_name" "api_kube_score_com" {
  certificate_arn = "arn:aws:acm:us-east-1:414416641486:certificate/bd748af3-d789-4c58-8108-79b707b7ba02"
  domain_name     = "api.kube-score.com"
}

resource "aws_api_gateway_base_path_mapping" "api_kube_score_com" {
  api_id      = aws_api_gateway_rest_api.kube_score_api.id
  stage_name  = aws_api_gateway_deployment.kube_score_api_v1.stage_name
  domain_name = aws_api_gateway_domain_name.api_kube_score_com.domain_name
}

resource "aws_api_gateway_deployment" "kube_score_api_v1" {
  depends_on = [aws_api_gateway_integration.kube_score_api]

  # Automatically trigger a deployment if the api has changed
  stage_description = <<DESCRIPTION
${aws_api_gateway_resource.score.id}
${aws_api_gateway_method.post_score.id}
${aws_api_gateway_integration.kube_score_api.id}
${aws_api_gateway_method.options_method.id}
${aws_api_gateway_integration.options_integration.id}
DESCRIPTION


  rest_api_id = aws_api_gateway_rest_api.kube_score_api.id
  stage_name  = "v1"

  lifecycle {
    create_before_destroy = true
  }
}

output "url" {
  value = "${aws_api_gateway_deployment.kube_score_api_v1.invoke_url}${aws_api_gateway_resource.score.path}"
}
