##################################
#              WEBSITE           #
##################################

resource "aws_s3_bucket" "website" {
    bucket = "static-website-content-${var.domain}"
}

resource "aws_s3_bucket_ownership_controls" "website" {
    bucket = aws_s3_bucket.website.id
    rule {
        object_ownership = "BucketOwnerEnforced"
    }
}

resource "aws_s3_bucket_public_access_block" "website" {
    bucket                  = aws_s3_bucket.website.id
    ignore_public_acls      = true
    block_public_acls       = true
    restrict_public_buckets = true
    block_public_policy     = true
}

##################################
#              LOGS              #
##################################

resource "aws_s3_bucket" "logs" {
    bucket = "static-website-logs-${var.domain}"
}

resource "aws_s3_bucket_ownership_controls" "logs" {
    bucket = aws_s3_bucket.logs.id
    
    rule {
        object_ownership = "ObjectWriter"
    }
}

resource "aws_s3_bucket_public_access_block" "logs" {
    bucket                  = aws_s3_bucket.logs.id
    
    ignore_public_acls      = true
    block_public_acls       = true
    restrict_public_buckets = true
    block_public_policy     = true
}

resource "aws_s3_bucket_acl" "logs" {
    depends_on = [
      aws_s3_bucket_ownership_controls.logs,
      aws_s3_bucket_public_access_block.logs
    ]

    bucket = aws_s3_bucket.logs.id
    acl    = "private"
}
