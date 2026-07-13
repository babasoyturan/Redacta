locals {
  application_namespace = var.application_namespace

  common_tags = merge(
    {
      Project     = "redacta"
      Environment = "development"
      ManagedBy   = "terraform"
      Stack       = "development"
    },
    var.tags
  )

  platform_admin_object_ids = setunion(
    var.platform_admin_object_ids,
    [data.azurerm_client_config.current.object_id]
  )

  waf_document_content_fields = [
    "originalText",
    "anonymizedText",
    "content",
    "document",
    "messages",
    "query",
    "original",
    "anonymized"
  ]

  waf_document_content_exclusions = [
    for field_name in local.waf_document_content_fields : {
      match_variable          = "RequestArgNames"
      selector                = field_name
      selector_match_operator = "Equals"
    }
  ]

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
