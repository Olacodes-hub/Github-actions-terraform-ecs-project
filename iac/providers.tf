# configure aws provider to establish a secure connection between terraform and aws
provider "aws" {
  region = us-east-1

  default_tags {
    tags = {
      "Automation"  = "terraform"
      "Project"     = var.project_name
      "Environment" = var.environment
    }
  }
}
