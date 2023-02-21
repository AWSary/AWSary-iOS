###########################
#--- S3 Backend Bucket ---#
###########################

resource "aws_s3_bucket" "terraform_bucket" {
  bucket        = "${var.organisation}-tf-${var.system}-state"
  force_destroy = true
  lifecycle {
    prevent_destroy = true
  }
  tags = var.tags
}

resource "aws_s3_bucket_acl" "tf_bucket_acl" {
  bucket = aws_s3_bucket.terraform_bucket.id
  acl    = "private"
}

resource "aws_s3_bucket_versioning" "tf_bucket_versioning" {
  bucket = aws_s3_bucket.terraform_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tf_bucket_encryption" {
  bucket = aws_s3_bucket.terraform_bucket.bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_policy" "delete_protection" {
  bucket = aws_s3_bucket.terraform_bucket.id

  policy = <<POLICY
{
  "Statement": [
    {
      "Sid": "tf-state-bucket-delete-protection",
      "Action": [
        "s3:DeleteBucket"
      ],
      "Effect": "Deny",
      "Resource": "arn:aws:s3:::${var.organisation}-tf-${var.system}-state",
      "Principal": {
        "AWS": [
          "*"
        ]
      }
    }
  ]
}
POLICY

  lifecycle {
    ignore_changes = [
      policy
    ]
  }
}

#############################
#--- DynamoDB State Lock ---#
#############################

resource "aws_dynamodb_table" "terraform_dynamodb" {
  name         = "${var.organisation}-tf-${var.system}-lock-table"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"
  attribute {
    name = "LockID"
    type = "S"
  }
  lifecycle {
    prevent_destroy = true
    ignore_changes = [
      read_capacity,
      write_capacity
    ]
  }
  tags = var.tags
}
