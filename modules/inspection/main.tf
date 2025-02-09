
## Provision the inspection vpcs if required
module "inspection_vpc" {
  source  = "appvia/network/aws"
  version = "0.3.4"

  availability_zones                     = var.connectivity_config.network.availability_zones
  enable_default_route_table_association = false
  enable_default_route_table_propagation = false
  enable_transit_gateway                 = true
  enable_transit_gateway_appliance_mode  = true
  name                                   = var.connectivity_config.network.name
  private_subnet_netmask                 = var.connectivity_config.network.private_netmask
  public_subnet_netmask                  = var.connectivity_config.network.public_netmask
  tags                                   = var.tags
  transit_gateway_id                     = module.tgw.ec2_transit_gateway_id
  vpc_cidr                               = var.connectivity_config.network.vpc_cidr
}

## Share the transit gateway with the other principals
resource "aws_ram_principal_association" "associations" {
  for_each = toset(var.ram_share_principals)

  principal          = each.value
  resource_share_arn = module.tgw.ram_resource_share_id
}

