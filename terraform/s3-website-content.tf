locals {
  content_type = {
    css:  "text/css"
    js:   "text/javascript"
    png:  "image/png+xml"
    svg:  "image/svg+xml"
    txt:  "text/plain"
  }
}

resource "aws_s3_object" "files" {
  for_each = fileset("${path.module}/../website", "**")

  bucket = aws_s3_bucket.website.id
  key    = each.value
  source = "${path.module}/../website/${each.value}"
  etag   = filemd5("${path.module}/../website/${each.value}")

  content_type = lookup(
    local.content_type,
    split(".", basename(each.value))[length(split(".", basename(each.value))) - 1],
    "text/html"
  )
}
