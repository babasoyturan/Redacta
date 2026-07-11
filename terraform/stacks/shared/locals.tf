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
}
