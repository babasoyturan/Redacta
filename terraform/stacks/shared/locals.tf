locals {
  common_tags = merge(
    {
      Project   = "redacta"
      ManagedBy = "terraform"
      Stack     = "shared"
    },
    var.tags
  )
}
