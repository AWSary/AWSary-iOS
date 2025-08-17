module "cloudfront" {
  source = "terraform-aws-modules/cloudfront/aws"
  providers = {
    aws = aws.us-east-1
  }

  aliases = ["cdn.awsary.com"]

  comment             = "CloudFront for cdn.awsary.com"
  enabled             = true
  is_ipv6_enabled     = true
  price_class         = "PriceClass_All"
  retain_on_delete    = false
  wait_for_deployment = false

  create_origin_access_identity = true
  origin_access_identities = {
    s3_bucket_one = "CloudFront for cdn.awsary.com can access"
  }

  create_origin_access_control = true
  origin_access_control = {
    s3_oac = {
      description      = "CloudFront access to S3"
      origin_type      = "s3"
      signing_behavior = "always"
      signing_protocol = "sigv4"
    }
  }

  # logging_config = {
  #   bucket = "logs-awsary-cdn.s3.amazonaws.com"
  # }

  origin = {
    s3_oac = {
      domain_name           = module.s3_bucket.s3_bucket_bucket_regional_domain_name
      origin_access_control = "s3_oac"
    }
  }

  # origin_group = {
  #   group_one = {
  #     failover_status_codes    = [403, 404, 500, 502]
  #     primary_member_origin_id = "s3_one"
  #   }
  # }

  default_cache_behavior = {
    target_origin_id       = "s3_oac"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = ["GET", "HEAD", "OPTIONS"]
    cached_methods  = ["GET", "HEAD"]
    compress        = true
    query_string    = true

    # This is id for SecurityHeadersPolicy copied from https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/using-managed-response-headers-policies.html
    response_headers_policy_id = "67f7725c-6f97-4210-82d7-5512b31e9d03"
    cache_policy_id            = "658327ea-f89d-4fab-a63d-7e88639e58f6"
    use_forwarded_values       = false
  }


  ordered_cache_behavior = [
    {
      path_pattern           = "*"
      target_origin_id       = "s3_oac"
      viewer_protocol_policy = "redirect-to-https"

      allowed_methods = ["GET", "HEAD", "OPTIONS"]
      cached_methods  = ["GET", "HEAD"]
      compress        = true
      query_string    = true

      cache_policy_id      = "658327ea-f89d-4fab-a63d-7e88639e58f6"
      use_forwarded_values = false
    }
  ]

  viewer_certificate = {
    acm_certificate_arn = module.acm.acm_certificate_arn
    ssl_support_method  = "sni-only"
  }
}


data "aws_route53_zone" "this" {
  name = local.domain_name
}

module "acm" {
  source  = "terraform-aws-modules/acm/aws"
  version = "~> 4.0"
  providers = {
    aws = aws.us-east-1
  }

  domain_name               = "awsary.com"
  zone_id                   = data.aws_route53_zone.this.id
  subject_alternative_names = ["cdn.awsary.com"]
}


data "aws_iam_policy_document" "s3_policy" {
  # Origin Access Identities
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${module.s3_bucket.s3_bucket_arn}/*"]

    principals {
      type        = "AWS"
      identifiers = module.cloudfront.cloudfront_origin_access_identity_iam_arns
    }
  }

  # Origin Access Controls
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${module.s3_bucket.s3_bucket_arn}/*"]

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = [module.cloudfront.cloudfront_distribution_arn]
    }
  }
}

resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = module.s3_bucket.s3_bucket_id
  policy = data.aws_iam_policy_document.s3_policy.json
}