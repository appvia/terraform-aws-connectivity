
locals {
  ## The current account id
  account_id = data.aws_caller_identity.current.account_id
  ## The current region
  region = data.aws_region.current.region
  ## The tags to use
  tags = merge(var.tags, {})
  ## Indicates if we have egress configuration
  enable_egress = var.services.egress != null
  ## Indicates if we have ingress configuration
  enable_ingress = var.services.ingress != null
  ## Indicates if we should provision a endpoints vpc
  enable_endpoints = var.services.endpoints != null
  ## Indicates if we should provision a central dns for private hosted zones
  enable_dns = var.services.dns != null
}
