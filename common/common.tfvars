
project = "#{project_name}#"
environment = "#{environment}#"
owner = "#{owner}#"
region = "#{deployment_region}#"

required_tags = {
  Project = "#{project_name}#",
  Environment = "#{environment}#",
  Owner = "#{owner}#",
  ManagedBy = "Tofu-Terragrunt"
}

profile = {
   "#{environment}#"= {
    region = "#{deployment_region}#"
    profile = "#{deployment_profile}#"

  }
}