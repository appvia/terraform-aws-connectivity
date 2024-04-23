
## Provision a network for the endpoints vpc 
module "endpoints_vpc" {
  count   = local.enable_endpoints ? 1 : 0
  source  = "appvia/network/aws"
  version = "0.3.0"

  availability_zones                    = var.connectivity_config.endpoints.network.availability_zones
  enable_transit_gateway                = true
  enable_transit_gateway_appliance_mode = true
  name                                  = var.connectivity_config.endpoints.network.name
  private_subnet_netmask                = var.connectivity_config.endpoints.network.private_netmask
  tags                                  = var.tags
  transit_gateway_id                    = module.tgw.ec2_transit_gateway_id
  vpc_cidr                              = var.connectivity_config.endpoints.network.vpc_cidr
}

## Provision if required the shared private endpoints
module "endpoints" {
  count   = local.enable_endpoints ? 1 : 0
  source  = "appvia/private-endpoints/aws"
  version = "0.2.1"

  name      = var.connectivity_config.endpoints.network.name
  endpoints = var.connectivity_config.endpoints.services
  tags      = var.tags

  network = {
    private_subnet_cidrs = module.endpoints_vpc[0].private_subnet_cidrs
    vpc_id               = module.endpoints_vpc[0].vpc_id
  }

  resolvers = {
    outbound = {
      create            = true
      ip_address_offset = 10
    }
  }
}
