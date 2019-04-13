locals {
  s3_origin_id = "S3-kube-score.com"
}

resource "aws_cloudfront_distribution" "kube_score_distribution" {
  origin {
    domain_name = "${aws_s3_bucket.kube_score.bucket_domain_name}"
    origin_id   = "${local.s3_origin_id}"

    s3_origin_config {
      origin_access_identity = "origin-access-identity/cloudfront/EPWSTV8SWLQGI"
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  logging_config {
    include_cookies = false
    bucket          = "gustav-tv-logs.s3.amazonaws.com"
    prefix          = "kube-score"
  }

  aliases = ["kube-score.com", "www.kube-score.com"]

  default_cache_behavior {
    allowed_methods  = ["HEAD", "GET"]
    cached_methods   = ["HEAD", "GET"]
    target_origin_id = "${local.s3_origin_id}"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 600
    max_ttl                = 600
  }

  price_class = "PriceClass_100"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    minimum_protocol_version = "TLSv1.1_2016"
    ssl_support_method       = "sni-only"
    acm_certificate_arn      = "arn:aws:acm:us-east-1:414416641486:certificate/0fd52e43-63bc-4c27-9048-f302ed3bfcd3"
  }
}
