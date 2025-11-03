# Load variables in locals
# Load variables in locals
locals {
  # Default values for variables
  profile           = "#{deployment_profile}#"
  project           = "#{project_name}#"
  deployment_region = "#{deployment_region}#"
  provider          = "#{cloud_provider}#"
  client = "thothctl"

  environment = get_env("TF_VAR_ENVIRONMENT", "dev")
  # Set tags according to company policies
  tags = {
    ProjectCode = "#{project_name}#"
    Framework   = "DevSecOps-IaC"
  }

  # Backend Configuration
  backend_region        = "#{deployment_region}#"
  backend_bucket_name   = "#{backend_bucket}#"
  backend_profile       = "#{deployment_profile}#"
  backend_dynamodb_lock = "#{backend_dynamodb}#"
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
  #{deployment_profile}#     = {}
}
variable "project" {
  type        = string
  description = "Project tool"
}
variable "profile" {
  description = "Variable for credentials management."
  #{deployment_profile}# = {
    #{deployment_profile}# = {
      profile = "#{deployment_profile}#"
      region = "#{deployment_region}#"
}
    dev  = {
      profile = "#{deployment_profile}#"
      region = "#{deployment_region}#"
}
    prod = {
      profile = "#{deployment_profile}#"
      region = "#{deployment_region}#"
    
}
  }

}


provider "#{cloud_provider}#" {
  region  = var.profile[terraform.workspace]["region"]
  profile = var.profile[terraform.workspace]["profile"]

  #{deployment_profile}#_tags {
    tags = var.required_tags

}
}

EOF
}
