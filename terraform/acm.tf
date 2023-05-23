data "aws_route53_zone" "my_domain" {
  name         = var.domain
  private_zone = false
}

resource "aws_acm_certificate" "website" {
    provider = aws.acm
    
    domain_name       = var.domain
    subject_alternative_names = ["*.${var.domain}"]
    validation_method = "DNS"
}

resource "aws_route53_record" "my_domain" {
  for_each = {
    for dvo in aws_acm_certificate.website.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 300
  type            = each.value.type
  zone_id         = data.aws_route53_zone.my_domain.zone_id
}

resource "aws_acm_certificate_validation" "website" {
    provider = aws.acm
    
    certificate_arn         = aws_acm_certificate.website.arn
    validation_record_fqdns = [
        for record in aws_route53_record.my_domain : record.fqdn
    ]
}
