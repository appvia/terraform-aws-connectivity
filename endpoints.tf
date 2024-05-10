
## Provision a network for the endpoints vpc 
module "endpoints_vpc" {
  count   = local.enable_endpoints ? 1 : 0
  source  = "appvia/network/aws"
  version = "0.3.0"

  availability_zones                     = var.connectivity_config.endpoints.network.availability_zones
  enable_default_route_table_association = false
  enable_default_route_table_propagation = false
  enable_ipam                            = var.connectivity_config.endpoints.network.ipam_pool_id != null
  enable_transit_gateway                 = true
  enable_transit_gateway_appliance_mode  = true
  ipam_pool_id                           = var.connectivity_config.endpoints.network.ipam_pool_id
  name                                   = var.connectivity_config.endpoints.network.name
  private_subnet_netmask                 = var.connectivity_config.endpoints.network.private_netmask
  tags                                   = var.tags
  transit_gateway_id                     = module.tgw.ec2_transit_gateway_id
  vpc_cidr                               = var.connectivity_config.endpoints.network.vpc_cidr
  vpc_netmask                            = var.connectivity_config.endpoints.network.vpc_netmask
}

## Provision if required the shared private endpoints
module "endpoints" {
  count   = local.enable_endpoints ? 1 : 0
  source  = "appvia/private-endpoints/aws"
  version = "0.2.2"

  name      = var.connectivity_config.endpoints.network.name
  endpoints = var.connectivity_config.endpoints.services
  tags      = var.tags

  network = {
    create                    = false
    private_subnet_cidr_by_id = module.endpoints_vpc[0].private_subnet_cidr_by_id
    transit_gateway_id        = module.tgw.ec2_transit_gateway_id
    vpc_id                    = module.endpoints_vpc[0].vpc_id
  }

  resolvers = {
    outbound = {
      create            = true
      ip_address_offset = 10
    }
  }

  sharing = {
    principals = values(var.connectivity_config.endpoints.sharing.principals)
  }
}
