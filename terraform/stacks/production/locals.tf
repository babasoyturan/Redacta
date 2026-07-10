locals {
  application_namespace = var.application_namespace

  common_tags = merge(
    {
      Project     = "redacta"
      Environment = "production"
      ManagedBy   = "terraform"
      Stack       = "production"
    },
    var.tags
  )

  workload_identities = {
    documentService = {
      name_suffix          = "document-service"
      service_account_name = "redacta-document-service"
    }
    authenticationService = {
      name_suffix          = "authentication-service"
      service_account_name = "redacta-authentication-service"
    }
    anonymizationService = {
      name_suffix          = "anonymization-service"
      service_account_name = "redacta-anonymization-service"
    }
    genaiService = {
      name_suffix          = "genai-service"
      service_account_name = "redacta-genai-service"
    }
    keycloak = {
      name_suffix          = "keycloak"
      service_account_name = "redacta-keycloak"
    }
  }
}
