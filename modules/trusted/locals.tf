
locals {
  ## Indicates if we have egress configuration
  enable_egress = var.services.egress != null
  ## Indicates if we have ingress configuration
  enable_ingress = var.services.ingress != null
  ## Indicates if we should provision a endpoints vpc
  enable_endpoints = var.services.endpoints != null
  ## Indicates if we should provision a central dns for private hosted zones
  enable_dns = var.services.dns != null
  ## The tags to use
  tags = var.tags
  ## The current region
  region = data.aws_region.current.name
  ## The current account id
  account_id = data.aws_caller_identity.current.account_id
  ## The transit gateway attaccment id for the endpoints vpc
  endpoints_vpc_attachment_id = local.enable_endpoints ? module.endpoints_vpc[0].transit_gateway_attachment_id : null
  ## Should we enable default propation on the vpc
  enable_default_route_table_propagation = true
  ## Should we enable default association on the vpc
  enable_default_route_table_association = false
}
