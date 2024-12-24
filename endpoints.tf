
## Provision an egress vpc if required 
module "endpoints_vpc" {
  count   = local.enable_endpoints ? 1 : 0
  source  = "appvia/network/aws"
  version = "0.3.3"

  availability_zones                     = var.services.endpoints.network.availability_zones
  enable_default_route_table_association = local.enable_default_route_table_association
  enable_default_route_table_propagation = local.enable_default_route_table_propagation
  enable_ipam                            = var.services.endpoints.network.ipam_pool_id != null
  enable_transit_gateway                 = true
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
  version = "0.2.10"

  name      = var.services.endpoints.network.name
  endpoints = var.services.endpoints.services
  region    = local.region
  tags      = var.tags

  network = {
    create                    = false
    name                      = var.services.endpoints.network.name
    private_subnet_cidr_by_id = module.endpoints_vpc[0].private_subnet_cidr_by_id
    vpc_dns_resolver          = cidrhost(module.endpoints_vpc[0].vpc_cidr, 2)
    vpc_id                    = module.endpoints_vpc[0].vpc_id
  }

  resolvers = {
    outbound = {
      create            = true
      ip_address_offset = 10
    }
  }

  sharing = {
    principals = var.services.endpoints.sharing.principals
  }

  depends_on = [module.endpoints_vpc]
}
