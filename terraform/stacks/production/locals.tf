locals {
  common_tags = merge(
    {
      Project     = "redacta"
      Environment = "production"
      ManagedBy   = "terraform"
      Stack       = "production"
    },
    var.tags
  )
}
