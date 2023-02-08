#      _    ____ ___   ____                        _
#     / \  |  _ \_ _| |  _ \  ___  _ __ ___   __ _(_)_ __
#    / _ \ | |_) | |  | | | |/ _ \| '_ ` _ \ / _` | | '_ \
#   / ___ \|  __/| |  | |_| | (_) | | | | | | (_| | | | | |
#  /_/   \_\_|  |___| |____/ \___/|_| |_| |_|\__,_|_|_| |_|

resource "aws_api_gateway_domain_name" "custom_domain" {
  certificate_arn = var.certificate
  domain_name     = var.domain
  security_policy = "TLS_1_2"
}

#   ____             _         ____ _____
#  |  _ \ ___  _   _| |_ ___  | ___|___ /
#  | |_) / _ \| | | | __/ _ \ |___ \ |_ \
#  |  _ < (_) | |_| | ||  __/  ___) |__) |
#  |_| \_\___/ \__,_|\__\___| |____/____/

resource "aws_route53_record" "record" {
  name    = aws_api_gateway_domain_name.custom_domain.domain_name
  type    = "A"
  zone_id = var.zone_id

  alias {
    evaluate_target_health = true
    name                   = aws_api_gateway_domain_name.custom_domain.cloudfront_domain_name
    zone_id                = aws_api_gateway_domain_name.custom_domain.cloudfront_zone_id
  }
}

#      _    ____ ___    ____       _
#     / \  |  _ \_ _|  / ___| __ _| |_ _____      ____ _ _   _
#    / _ \ | |_) | |  | |  _ / _` | __/ _ \ \ /\ / / _` | | | |
#   / ___ \|  __/| |  | |_| | (_| | ||  __/\ V  V / (_| | |_| |
#  /_/   \_\_|  |___|  \____|\__,_|\__\___| \_/\_/ \__,_|\__, |
#                                                        |___/

resource "aws_api_gateway_rest_api" "api" {
  name = "${var.environment}-${var.app}"

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  tags = {
    Name        = "${var.environment}-${var.app} API Gateway"
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
  name               = "${var.app}-api-whitelist-ips"
  description        = "${var.app} API IP Set"
  scope              = "REGIONAL"
  ip_address_version = "IPV4"
  addresses          = var.whitelist_ips

  tags = {
    Name        = "${var.app} API Whitelist IP Set"
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
  name     = "${var.app}-api-whitelist-rule-group"
  scope    = "REGIONAL"
  capacity = 1

  rule {
    name     = "${var.app}-api-whitelist-rule"
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
      metric_name                = "${var.app}-api-whitelist-rule"
      sampled_requests_enabled   = false
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = false
    metric_name                = "${var.app}-api-whitelist-rule-group"
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
  name  = "${var.app}-api-waf"
  scope = "REGIONAL"

  default_action {
    allow {
    }
  }

  rule {
    name     = "${var.app}-api-whitelist-rule"
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
      metric_name                = "${var.app}-api-whitelist-rule-group"
      sampled_requests_enabled   = false
    }
  }

  rule {
    name     = "${var.app}-api-sql-rule"
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
      metric_name                = "${var.app}-api-sql-rule-group"
      sampled_requests_enabled   = false
    }
  }

  rule {
    name     = "${var.app}-api-bad-inputs-rule"
    priority = 3

    override_action {
      count {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.app}-api-bad-inputs-rule-group"
      sampled_requests_enabled   = false
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.app}-api-waf"
    sampled_requests_enabled   = false
  }

  depends_on = [
    aws_wafv2_rule_group.waf_rule_group
  ]

  tags = {
    Name        = "${var.app} API WAF ACL"
    CostCenter  = var.app
    Environment = var.environment
  }
}

resource "aws_api_gateway_deployment" "api_deployment" {
  rest_api_id = aws_api_gateway_rest_api.api.id

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_api_gateway_rest_api.api
  ]
}

resource "aws_api_gateway_stage" "api_gateway_stage" {
  deployment_id = aws_api_gateway_deployment.api_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.api.id
  stage_name    = var.environment

  xray_tracing_enabled = true

  depends_on = [
    aws_api_gateway_deployment.api_deployment,
    aws_api_gateway_rest_api.api,
    var.environment
  ]
}

resource "aws_wafv2_web_acl_association" "api_gateway_waf_association" {
  resource_arn = aws_api_gateway_stage.api_gateway_stage.arn
  web_acl_arn  = aws_wafv2_web_acl.waf.arn

  depends_on = [
    aws_api_gateway_stage.api_gateway_stage,
    aws_wafv2_web_acl.waf
  ]
}

resource "aws_api_gateway_base_path_mapping" "api_gateway_mapping" {
  api_id      = aws_api_gateway_rest_api.api.id
  domain_name = aws_api_gateway_domain_name.custom_domain.domain_name
  stage_name  = aws_api_gateway_stage.api_gateway_stage.stage_name

  depends_on = [
    aws_api_gateway_rest_api.api,
    aws_api_gateway_stage.api_gateway_stage,
    var.environment
  ]
}

#   ____                     _
#  / ___|  ___  ___ _ __ ___| |_ ___
#  \___ \ / _ \/ __| '__/ _ \ __/ __|
#   ___) |  __/ (__| | |  __/ |_\__ \
#  |____/ \___|\___|_|  \___|\__|___/

resource "aws_secretsmanager_secret" "lambda_secrets" {
  name = "${var.app}/${var.environment}/lambda/secrets"

  tags = {
    Name        = "${var.environment}-${var.app} Lambda Secrets"
    CostCenter  = var.app
    Environment = var.environment
  }
}

resource "aws_secretsmanager_secret_version" "lambda_secrets_version" {
  secret_id = aws_secretsmanager_secret.lambda_secrets.id
  secret_string = jsonencode({
    "rest_api_id" : "${aws_api_gateway_rest_api.api.id}",
    "rest_api_root" : "${aws_api_gateway_rest_api.api.root_resource_id}",
    "subnet_a" : "${var.private_subnets[0]}",
    "subnet_b" : "${var.private_subnets[1]}",
    "lambda_sg" : "${var.lambda_sg}",
    "db_proxy_endpoint" : "postgresql://${var.db_username}:${var.db_password}@${var.db_proxy_endpoint}:${var.db_port}/${var.db_name}?schema=public"
  })
}

