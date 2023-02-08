#   _   _           _           _   _____
#  | | | | ___  ___| |_ ___  __| | |__  /___  _ __   ___
#  | |_| |/ _ \/ __| __/ _ \/ _` |   / // _ \| '_ \ / _ \
#  |  _  | (_) \__ \ ||  __/ (_| |  / /| (_) | | | |  __/
#  |_| |_|\___/|___/\__\___|\__,_| /____\___/|_| |_|\___|

resource "aws_route53_zone" "hosted_zone" {
  name = "${var.domain}."
}

#    ____          _
#   / ___|___ _ __| |_
#  | |   / _ \ '__| __|
#  | |__|  __/ |  | |_
#   \____\___|_|   \__|

resource "aws_acm_certificate" "cert" {
  domain_name               = "*.${var.domain}"
  validation_method         = "DNS"
  subject_alternative_names = ["${var.domain}"]
}

resource "aws_route53_record" "certs" {
  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = aws_route53_zone.hosted_zone.zone_id
}
