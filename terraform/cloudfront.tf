data "aws_cloudfront_cache_policy" "aws-managed" {
  name = "Managed-CachingOptimized"
}

locals {
  s3_origin_id = "website-origin"
}

resource "aws_cloudfront_origin_access_control" "website" {
    name                              = "access-website"
    description                       = "Restrict S3 access to CloudFront"
    origin_access_control_origin_type = "s3"
    signing_behavior                  = "always"
    signing_protocol                  = "sigv4"
}

data "aws_iam_policy_document" "oac_policy" {
    statement {
        sid       = "AllowCloudFront"
        actions   = ["s3:GetObject"]
        resources = ["${aws_s3_bucket.website.arn}/*"]
        principals {
            type        = "Service"
            identifiers = ["cloudfront.amazonaws.com"]
        }
        condition {
            test     = "StringEquals"
            variable = "AWS:SourceArn"
            values   = [aws_cloudfront_distribution.distribution.arn]
        }
    }
}

resource "aws_s3_bucket_policy" "oac" {
  bucket = aws_s3_bucket.website.id
  policy = data.aws_iam_policy_document.oac_policy.json
}

resource "aws_cloudfront_response_headers_policy" "website" {
    name = "mozilla-approved-response-headers-v2"
    comment = "Adds a set of security headers to every response"

    security_headers_config {
        content_type_options {
            override = true
        }
        frame_options {
            frame_option = "DENY"
            override = true
        }
        referrer_policy {
            referrer_policy = "strict-origin-when-cross-origin"
            override = true
        }
        xss_protection {
            mode_block = true
            protection = true
            override = true
        }
        strict_transport_security {
            access_control_max_age_sec = "31536000"
            preload = true
            override = true
        }
        content_security_policy {
            content_security_policy = "default-src 'none'; style-src-elem 'self' https://fonts.googleapis.com; font-src https://fonts.gstatic.com; img-src 'self'; script-src 'unsafe-inline'; style-src 'self'; object-src 'none'"
            override = true
        }
    }
}

resource "aws_cloudfront_distribution" "distribution" {
    origin {
        domain_name              = aws_s3_bucket.website.bucket_regional_domain_name
        origin_access_control_id = aws_cloudfront_origin_access_control.website.id
        origin_id                = local.s3_origin_id
    }

    enabled             = true
    is_ipv6_enabled     = true
    default_root_object = "index.html"

    price_class = "PriceClass_All"

    aliases = ["www.${var.domain}"]

    logging_config {
        include_cookies = true
        bucket          = aws_s3_bucket.logs.bucket_domain_name
    }

    viewer_certificate {
        acm_certificate_arn = aws_acm_certificate.website.arn
        minimum_protocol_version = "TLSv1.2_2021"
        ssl_support_method  = "sni-only"
    }

    default_cache_behavior {
        allowed_methods  = ["GET", "HEAD"]
        cached_methods   = ["GET", "HEAD"]
        target_origin_id = local.s3_origin_id

        cache_policy_id = data.aws_cloudfront_cache_policy.aws-managed.id

        viewer_protocol_policy = "redirect-to-https"
        
        response_headers_policy_id = aws_cloudfront_response_headers_policy.website.id
    }

    custom_error_response {
        error_code = 403
        error_caching_min_ttl = 300
        response_page_path = "/404.html"
        response_code = 404
    }

    restrictions {
        geo_restriction {
            restriction_type = "none"
        }
    }
}
