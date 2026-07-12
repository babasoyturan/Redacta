locals {
  common_tags = merge(
    {
      Project   = "redacta"
      ManagedBy = "terraform"
      Stack     = "shared"
    },
    var.tags
  )

  github_actions_federated_subjects = {
    for key, environment_name in var.github_actions_environments :
    key => "repo:${var.github_actions_repository}:environment:${environment_name}"
  }

  github_actions_terraform_identities = {
    shared = {
      name        = "id-redacta-github-terraform-shared-swec"
      environment = var.github_actions_environments.development
    }
    development = {
      name        = "id-redacta-github-terraform-dev-swec"
      environment = var.github_actions_environments.development
    }
    production = {
      name        = "id-redacta-github-terraform-prod-swec"
      environment = var.github_actions_environments.production
    }
  }

  github_actions_terraform_subjects = {
    for key, identity in local.github_actions_terraform_identities :
    key => "repo:${var.github_actions_repository}:environment:${identity.environment}"
  }

  development_resource_group_id = "${data.azurerm_subscription.current.id}/resourceGroups/${var.development_resource_group_name}"
  production_resource_group_id  = "${data.azurerm_subscription.current.id}/resourceGroups/${var.production_resource_group_name}"
}
