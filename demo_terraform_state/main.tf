provider "aws" {
region = "ap-southeast-1"
}

#create a s3 bucket to store terraform state
resource "aws_s3_bucket" "terrraform_bucket_state" {
  bucket = "terraform-up-and-running-state-praveendasan"
  force_destroy = true # This is to ensure the bucket can be deleted if needed
  #prevent deletion of the bucket

}

# Enable versioning for the S3 bucket
resource "aws_s3_bucket_versioning" "s3_enable_versioning" {
  bucket = aws_s3_bucket.terrraform_bucket_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Enable server-side encryption with AES-256
resource "aws_s3_bucket_server_side_encryption_configuration" "encrypt_default" {
  bucket = aws_s3_bucket.terrraform_bucket_state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
  
}

#explicitly block public access to the bucket
resource "aws_s3_bucket_public_access_block" "block_public_access" {
  bucket = aws_s3_bucket.terrraform_bucket_state.id
  block_public_acls       = true
  block_public_policy     = true
    ignore_public_acls      = true
    restrict_public_buckets = true
}

#dynamodb table for state locking
resource "aws_dynamodb_table" "terraform_state_lock" {
  name         = "terraform-up-and-running-lock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"   
    attribute {
        name = "LockID"
        type = "S"
    }
}

#add the backend configuration to the main.tf file
#before deleting the backend configuration, make sure to run `terraform init -migrate-state` to migrate the state to the new backend
/*
terraform {
  backend "s3" {
    bucket = "terraform-up-and-running-state-praveendasan"
    key            = "terraform.tfstate"
    region         = "ap-southeast-1"
    #dynamodb_table = "terraform-up-and-running-lock"
    use_lockfile = false
    encrypt        = true
  }
}
*/


output "s3_bucket_arn" {
  value = aws_s3_bucket.terrraform_bucket_state.arn
  description = "The ARN of the S3 bucket used for Terraform state storage"
  
}

output "dynamodb_table_name" {
  value = aws_dynamodb_table.terraform_state_lock.name
  description = "The name of the DynamoDB table used for state locking"
  
}
