locals {
  common_tags = merge(
    {
      Project     = "redacta"
      Environment = "development"
      ManagedBy   = "terraform"
      Stack       = "development"
    },
    var.tags
  )
}
