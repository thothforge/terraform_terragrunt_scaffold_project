# Load variables in locals
# Load variables in locals
locals {
  # Default values for variables
  profile           = "default"
  project           = "test-wrapper"
  deployment_region = "us-east-2"
  provider          = "aws"
  client = "thothctl"

  # Set tags according to company policies
  tags = {
    ProjectCode = "test-wrapper"
    Framework   = "DevSecOps-IaC"
  }

  # Backend Configuration
  backend_region        = "us-east-2"
  backend_bucket_name   = "test-wrapper-tfstate"
  backend_profile       = "default"
  backend_dynamodb_lock = "db-terraform-lock"
  backend_key           = "terraform.tfstate"
  backend_encrypt = true
  # format cloud provider/client/projectname
  project_folder        = "${local.provider}/${local.client}/${local.project}"

}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
variable "required_tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}
variable "project" {
  type        = string
  description = "Project tool"
}
variable "profile" {
  description = "Variable for credentials management."
  default = {
    default = {
      profile = "default"
      region = "us-east-2"
}
    dev  = {
      profile = "default"
      region = "us-east-2"
}
    prod = {
      profile = "default"
      region = "us-east-2"
    
}
  }

}


provider "aws" {
  region  = var.profile[terraform.workspace]["region"]
  profile = var.profile[terraform.workspace]["profile"]

  default_tags {
    tags = var.required_tags

}
}

EOF
}
