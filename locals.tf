
locals {
  ## Indicates the inspection connectivity layout 
  enable_inspection_all = var.connectivity_config.inspection_with_all != null
  ## Indicates the trusted network connectivity layout 
  enable_trusted = var.connectivity_config.trusted != null
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

  ## The transit gateway attaccment id for the endpoints vpc 
  endpoints_vpc_attachment_id = local.enable_endpoints ? module.endpoints_vpc[0].transit_gateway_attachment_id : null
  ## The workloads routing table for the trusted configuration   
  #trusted_workloads_routing_table_id = local.enable_trusted ? module.tgw.ec2_transit_gateway_association_default_route_table_id : null

  ## Should we enable default propation on the vpc 
  enable_default_route_table_propagation = local.enable_trusted ? false : true
  ## Should we enable default association on the vpc 
  enable_default_route_table_association = local.enable_trusted ? false : true
}
