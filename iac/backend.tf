# store the terraform state file in s3 and lock with dynamodb
terraform {
  backend "s3" {
    bucket         = "cicd-rentzone-state-bucket"
    key            = "cicd-rentzone/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "cicd-state-lock"
  }
}
