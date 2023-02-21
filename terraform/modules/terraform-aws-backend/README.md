# Terraform backend

## Resources created by this module

- S3 Bucket (State storage) and Bucket Policy
- DynamoDB (Locking table)

## Providers

| Name | Version |
|------|---------|
| aws | n/a |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:-----:|
| organisation | Name of the customer organisation. | `string` | `""` | no |
| system | Name of a dedicated system or application | `string` | `""` | no |

## Outputs

| Name | Description |
|------|-------------|
| dynamodb\_table\_arn | The ARN of the bucket. |
| s3\_bucket\_arn | The ARN of the bucket. |
| s3\_bucket\_id | The name of the bucket. |

## Example 

```
terraform {
  required_version = ">= 0.12"

  backend "s3" {
    region         = 
    bucket         = 
    key            = 
    dynamodb_table = 
    encrypt        = 
    role_arn       = 
  }
}

module "terraform_backend" {
  source = "git::ssh://.../tf_module_aws_terraform_backend.git?ref=v1.0.0"

  organisation = local.organisation
  system       = local.system
}
```


