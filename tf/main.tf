terraform {
  backend "s3" {
    bucket = "sakamotodesu-sakamoto-ninja-tfstate"
    key    = "terraform.tfstate"
    region = "ap-northeast-1"
  }
  required_version = "= 0.12.23"
}

provider "aws" {
  version = "= 2.52.0"
  // ACMがus-east-1 にないとCloudFrontのカスタムドメインに設定できない。
  region = "us-east-1"
}

data "aws_route53_zone" "sakamoto-ninja" {
  name = "sakamoto.ninja"
}

resource "aws_route53_record" "sakamoto-ninja-record" {
  zone_id = data.aws_route53_zone.sakamoto-ninja.zone_id
  name    = "sakamoto.ninja"
  type    = "A"
  alias {
    evaluate_target_health = false
    name                   = aws_cloudfront_distribution.sakamoto-ninja-site.domain_name
    zone_id                = aws_cloudfront_distribution.sakamoto-ninja-site.hosted_zone_id
  }
}

resource "aws_acm_certificate" "sakamoto-ninja-acm" {
  domain_name               = data.aws_route53_zone.sakamoto-ninja.name
  subject_alternative_names = []
  validation_method         = "DNS"
  lifecycle {
    create_before_destroy = true
  }
  tags = {
    "Service" = "sakamoto-ninja"
  }
}

resource "aws_s3_bucket" "sakamoto-ninja-site" {
  acl           = "private"
  bucket        = "sakamoto-ninja-site"
  force_destroy = false
  tags = {
    "Service" = "sakamoto-ninja"
  }
}

resource "aws_s3_bucket_policy" "sakamoto-ninja-site" {
  bucket = aws_s3_bucket.sakamoto-ninja-site.id
  policy = data.aws_iam_policy_document.sakamoto-ninja-site.json
}

data "aws_iam_user" "sakamoto" {
  user_name = "sakamoto"
}

data "aws_iam_policy_document" "sakamoto-ninja-site" {
  policy_id = "PolicyForCloudFrontPrivateContent"
  version   = "2012-10-17"
  statement {
    actions = [
    "s3:GetObject"]
    resources = [
    "${aws_s3_bucket.sakamoto-ninja-site.arn}/*"]
    sid = "1"
    principals {
      type = "AWS"
      identifiers = [
      aws_cloudfront_origin_access_identity.sakamoto-ninja-site.iam_arn]
    }
  }

  statement {
    actions = [
      "s3:DeleteObject",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:PutObject",
    ]
    effect = "Allow"
    principals {
      type = "AWS"
      identifiers = [
      data.aws_iam_user.sakamoto.arn]
    }
    resources = [
      aws_s3_bucket.sakamoto-ninja-site.arn,
      "${aws_s3_bucket.sakamoto-ninja-site.arn}/*",
    ]
    sid = "Stmt1592734946466"

  }
}

locals {
  s3_origin_id = "S3-sakamoto.ninja"
}
resource "aws_cloudfront_distribution" "sakamoto-ninja-site" {
  aliases = [
  "sakamoto.ninja"]
  default_root_object = "index.html"
  http_version        = "http2"
  enabled             = true
  is_ipv6_enabled     = true
  price_class         = "PriceClass_All"
  retain_on_delete    = false
  tags = {
    Service = "sakamoto-ninja"
  }
  wait_for_deployment = true

  default_cache_behavior {
    allowed_methods = [
      "GET",
      "HEAD",
    ]
    cached_methods = [
      "GET",
      "HEAD",
    ]
    compress               = false
    default_ttl            = 86400
    max_ttl                = 31536000
    min_ttl                = 0
    smooth_streaming       = false
    target_origin_id       = local.s3_origin_id
    trusted_signers        = []
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      headers                 = []
      query_string            = false
      query_string_cache_keys = []

      cookies {
        forward           = "none"
        whitelisted_names = []
      }
    }
  }

  origin {
    domain_name = aws_s3_bucket.sakamoto-ninja-site.bucket_domain_name
    origin_id   = local.s3_origin_id

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.sakamoto-ninja-site.cloudfront_access_identity_path
    }
  }

  restrictions {
    geo_restriction {
      locations        = []
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn            = aws_acm_certificate.sakamoto-ninja-acm.arn
    cloudfront_default_certificate = false
    minimum_protocol_version       = "TLSv1.2_2018"
    ssl_support_method             = "sni-only"
  }

}

resource "aws_cloudfront_origin_access_identity" "sakamoto-ninja-site" {
  comment = "sakamoto-ninja-site"
}

