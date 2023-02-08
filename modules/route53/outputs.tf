output "zone_id" {
  value = aws_route53_zone.hosted_zone.zone_id
}

output "cert" {
  value = aws_acm_certificate.cert.arn
}

