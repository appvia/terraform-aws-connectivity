
## Provision an egress vpc if required
module "endpoints_vpc" {
  count   = local.enable_endpoints ? 1 : 0
  source  = "appvia/network/aws"
  version = "0.4.0"

  availability_zones                     = var.services.endpoints.network.availability_zones
  enable_default_route_table_association = false
  enable_default_route_table_propagation = false
  ipam_pool_id                           = var.services.endpoints.network.ipam_pool_id
  name                                   = var.services.endpoints.network.name
  private_subnet_netmask                 = var.services.endpoints.network.private_netmask
  tags                                   = var.tags
  transit_gateway_id                     = module.tgw.ec2_transit_gateway_id
  vpc_cidr                               = var.services.endpoints.network.vpc_cidr
  vpc_netmask                            = var.services.endpoints.network.vpc_netmask
}

## Provision if required the shared private endpoints
module "endpoints" {
  count   = local.enable_endpoints ? 1 : 0
  source  = "appvia/private-endpoints/aws"
  version = "0.3.1"

  endpoints = var.services.endpoints.services
  name      = var.services.endpoints.network.name
  region    = local.region
  tags      = var.tags

  network = {
    name                      = var.services.endpoints.network.name
    private_subnet_cidr_by_id = module.endpoints_vpc[0].private_subnet_cidr_by_id
    vpc_dns_resolver          = cidrhost(module.endpoints_vpc[0].vpc_cidr, 2)
    vpc_id                    = module.endpoints_vpc[0].vpc_id
  }

  resolver_rules = {
    principals = try(var.services.endpoints.resolver_rules.principals, [])
  }

  resolvers = try(var.services.endpoints.resolver.enable, false) ? {
    outbound = {
      ip_address_offset = 10
    }
  } : null

  depends_on = [module.endpoints_vpc]
}

## We need to propagate the endpoints vpc into the trusted route table
resource "aws_ec2_transit_gateway_route_table_propagation" "trusted_endpoints" {
  count = local.enable_endpoints == true ? 1 : 0

  transit_gateway_attachment_id  = local.endpoints_vpc_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.trusted.id
}

## We need to propagate the dns_vpc into the untrusted route table
resource "aws_ec2_transit_gateway_route_table_propagation" "untrusted_dns" {
  count = local.enable_dns == true ? 1 : 0

  transit_gateway_attachment_id  = module.dns_vpc[0].transit_gateway_attachment_id
  transit_gateway_route_table_id = module.tgw.ec2_transit_gateway_association_default_route_table_id
}

## We need to associate the endpoints vpc with the trusted routing table
resource "aws_ec2_transit_gateway_route_table_association" "trusted_endpoints" {
  count = local.enable_endpoints == true ? 1 : 0

  replace_existing_association   = true
  transit_gateway_attachment_id  = local.endpoints_vpc_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.trusted.id
}

