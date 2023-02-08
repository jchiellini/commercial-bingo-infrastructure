#    ___    _    ___
#   / _ \  / \  |_ _|
#  | | | |/ _ \  | |
#  | |_| / ___ \ | |
#   \___/_/   \_\___|

resource "aws_cloudfront_origin_access_identity" "oai" {
  comment = "access-identity-${var.environment}-${var.app}.s3.us-east-1.amazonaws.com"
}

#   ____ _____   _                _        _
#  / ___|___ /  | |__  _   _  ___| | _____| |_
#  \___ \ |_ \  | '_ \| | | |/ __| |/ / _ \ __|
#   ___) |__) | | |_) | |_| | (__|   <  __/ |_
#  |____/____/  |_.__/ \__,_|\___|_|\_\___|\__|

resource "aws_s3_bucket" "ui" {
  bucket = "${var.environment}-${var.app}"

  website {
    error_document = "error.html"
    index_document = "index.html"
  }

  tags = {
    Name        = "${var.environment}-${var.app} S3 Bucket"
    CostCenter  = var.app
    Environment = var.environment
  }
}

resource "aws_s3_bucket_public_access_block" "ui_backend_access" {
  bucket = aws_s3_bucket.ui.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

data "aws_iam_policy_document" "s3_policy" {
  statement {
    sid     = "CloudFront Origin Access Identity"
    actions = ["s3:GetObject"]
    resources = [
      "${aws_s3_bucket.ui.arn}/*",
      "${aws_s3_bucket.ui.arn}"
    ]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.oai.iam_arn]
    }
  }
}

resource "aws_s3_bucket_policy" "ui" {
  bucket = aws_s3_bucket.ui.id
  policy = data.aws_iam_policy_document.s3_policy.json
}

#    ____ _                 _  __                 _
#   / ___| | ___  _   _  __| |/ _|_ __ ___  _ __ | |_
#  | |   | |/ _ \| | | |/ _` | |_| '__/ _ \| '_ \| __|
#  | |___| | (_) | |_| | (_| |  _| | | (_) | | | | |_
#   \____|_|\___/ \__,_|\__,_|_| |_|  \___/|_| |_|\__|

resource "aws_cloudfront_distribution" "ui_distribution" {
  origin {
    domain_name         = "${aws_s3_bucket.ui.bucket}.s3.${aws_s3_bucket.ui.region}.amazonaws.com"
    origin_id           = var.domain
    connection_attempts = 3
    connection_timeout  = 10

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.oai.cloudfront_access_identity_path
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  custom_error_response {
    error_caching_min_ttl = 0
    error_code            = 404
    response_code         = 200
    response_page_path    = "/index.html"
  }

  custom_error_response {
    error_caching_min_ttl = 10
    error_code            = 403
    response_code         = 200
    response_page_path    = "/index.html"
  }

  default_cache_behavior {
    viewer_protocol_policy = "redirect-to-https"
    compress               = true
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = var.domain
    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  aliases = [var.domain]

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn = var.certificate
    ssl_support_method  = "sni-only"
  }

  web_acl_id = aws_wafv2_web_acl.waf.arn

  depends_on = [
    aws_wafv2_web_acl.waf
  ]

  tags = {
    Name        = "${var.app}-${var.environment} Cloudfront"
    CostCenter  = var.app
    Environment = var.environment
  }
}

#   ___ ____    ____       _
#  |_ _|  _ \  / ___|  ___| |_
#   | || |_) | \___ \ / _ \ __|
#   | ||  __/   ___) |  __/ |_
#  |___|_|     |____/ \___|\__|

resource "aws_wafv2_ip_set" "whitelist_ips" {
  name               = "${var.app}-whitelist-ips"
  description        = "${var.app} IP Set"
  scope              = "CLOUDFRONT"
  ip_address_version = "IPV4"
  addresses          = var.whitelist_ips

  tags = {
    Name        = "${var.app} Whitelist IP Set"
    CostCenter  = var.app
    Environment = var.environment
  }
}

#   ____        _         ____
#  |  _ \ _   _| | ___   / ___|_ __ ___  _   _ _ __
#  | |_) | | | | |/ _ \ | |  _| '__/ _ \| | | | '_ \
#  |  _ <| |_| | |  __/ | |_| | | | (_) | |_| | |_) |
#  |_| \_\\__,_|_|\___|  \____|_|  \___/ \__,_| .__/
#                                             |_|

resource "aws_wafv2_rule_group" "waf_rule_group" {
  name     = "${var.app}-whitelist-rule-group"
  scope    = "CLOUDFRONT"
  capacity = 1

  rule {
    name     = "${var.app}-whitelist-rule"
    priority = 1

    action {
      block {}
    }

    statement {
      not_statement {
        statement {
          ip_set_reference_statement {
            arn = aws_wafv2_ip_set.whitelist_ips.arn
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = false
      metric_name                = "${var.app}-whitelist-rule"
      sampled_requests_enabled   = false
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = false
    metric_name                = "${var.app}-whitelist-rule-group"
    sampled_requests_enabled   = false
  }

  depends_on = [
    aws_wafv2_ip_set.whitelist_ips
  ]

  tags = {
    Name        = "${var.app} Rule Group"
    CostCenter  = var.app
    Environment = var.environment
  }
}

#  __        ___    _____
#  \ \      / / \  |  ___|
#   \ \ /\ / / _ \ | |_
#    \ V  V / ___ \|  _|
#     \_/\_/_/   \_\_|
#

resource "aws_wafv2_web_acl" "waf" {
  name  = "${var.app}-waf"
  scope = "CLOUDFRONT"

  default_action {
    allow {
    }
  }

  rule {
    name     = "${var.app}-whitelist-rule"
    priority = 1

    override_action {
      count {}
    }

    statement {
      rule_group_reference_statement {
        arn = aws_wafv2_rule_group.waf_rule_group.arn
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.app}-whitelist-rule-group"
      sampled_requests_enabled   = false
    }
  }

  rule {
    name     = "${var.app}-sql-rule"
    priority = 2

    override_action {
      count {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesSQLiRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.app}-sql-rule-group"
      sampled_requests_enabled   = false
    }
  }


  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.app}-waf"
    sampled_requests_enabled   = false
  }

  depends_on = [
    aws_wafv2_rule_group.waf_rule_group
  ]

  tags = {
    Name        = "${var.app} WAF ACL"
    CostCenter  = var.app
    Environment = var.environment
  }
}

#   ____                        _
#  |  _ \  ___  _ __ ___   __ _(_)_ __
#  | | | |/ _ \| '_ ` _ \ / _` | | '_ \
#  | |_| | (_) | | | | | | (_| | | | | |
#  |____/ \___/|_| |_| |_|\__,_|_|_| |_|

resource "aws_route53_record" "record" {
  zone_id = var.zone_id
  name    = var.domain
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.ui_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.ui_distribution.hosted_zone_id
    evaluate_target_health = false
  }
}
