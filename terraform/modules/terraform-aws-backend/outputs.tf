output "s3_bucket_id" {
  description = "The name of the bucket."
  value       = aws_s3_bucket.terraform_bucket.id
}

output "s3_bucket_arn" {
  description = "The ARN of the bucket."
  value       = aws_s3_bucket.terraform_bucket.arn
}

output "dynamodb_table_arn" {
  description = "The ARN of the bucket."
  value       = aws_dynamodb_table.terraform_dynamodb.arn
}
