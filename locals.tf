
locals {
  ## Indicates the inspection connectivity layout 
  enable_inspection = var.connectivity_config.inspection != null
  ## Indicates the trusted network connectivity layout 
  enable_trusted = var.connectivity_config.trusted != null
  ## Indicates if we have egress configuration 
  enable_egress = var.connectivity_config.egress != null
  ## Indicates if we have ingress configuration 
  enable_ingress = var.connectivity_config.ingress != null
  ## Indicates if we should provision a endpoints vpc 
  enable_endpoints = var.connectivity_config.endpoints != null
}
