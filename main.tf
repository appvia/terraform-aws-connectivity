
## Provision the transit gateway
module "tgw" {
  source  = "terraform-aws-modules/transit-gateway/aws"
  version = "2.12.2"

  name                                   = var.name
  amazon_side_asn                        = var.amazon_side_asn
  description                            = var.description
  create_tgw_routes                      = false
  enable_auto_accept_shared_attachments  = true
  enable_default_route_table_association = true
  enable_default_route_table_propagation = true
  enable_dns_support                     = var.enable_dns_support
  enable_multicast_support               = var.enable_multicast_support
  enable_vpn_ecmp_support                = var.enable_vpn_ecmp_support
  ram_allow_external_principals          = var.enable_external_principals
  ram_name                               = var.ram_share_name
  ram_tags                               = var.tags
  tags                                   = var.tags
  tgw_default_route_table_tags           = var.tags
  tgw_route_table_tags                   = var.tags
  share_tgw                              = true
}

## Provision an egress vpc if required 
module "egress_vpc" {
  count   = local.enable_egress ? 1 : 0
  source  = "appvia/network/aws"
  version = "0.3.0"

  availability_zones                     = var.connectivity_config.egress.network.availability_zones
  enable_default_route_table_association = false
  enable_default_route_table_propagation = false
  enable_ipam                            = var.connectivity_config.egress.network.ipam_pool_id != null
  enable_nat_gateway                     = true
  enable_transit_gateway                 = true
  enable_transit_gateway_subnet_natgw    = true
  ipam_pool_id                           = var.connectivity_config.egress.network.ipam_pool_id
  name                                   = var.connectivity_config.egress.network.name
  nat_gateway_mode                       = "all_azs"
  private_subnet_netmask                 = var.connectivity_config.egress.network.private_netmask
  public_subnet_netmask                  = var.connectivity_config.egress.network.public_netmask
  tags                                   = var.tags
  transit_gateway_id                     = module.tgw.ec2_transit_gateway_id
  vpc_cidr                               = var.connectivity_config.egress.network.vpc_cidr
  vpc_netmask                            = var.connectivity_config.egress.network.vpc_netmask
}

## Provision an ingress vpc if required
module "ingress_vpc" {
  count   = local.enable_ingress ? 1 : 0
  source  = "appvia/network/aws"
  version = "0.3.0"

  availability_zones                     = var.connectivity_config.ingress.network.availability_zones
  enable_default_route_table_association = false
  enable_default_route_table_propagation = false
  enable_ipam                            = var.connectivity_config.ingress.network.ipam_pool_id != null
  enable_nat_gateway                     = false
  enable_transit_gateway                 = true
  ipam_pool_id                           = var.connectivity_config.ingress.network.ipam_pool_id
  name                                   = var.connectivity_config.ingress.network.name
  private_subnet_netmask                 = var.connectivity_config.ingress.network.private_netmask
  public_subnet_netmask                  = var.connectivity_config.ingress.network.public_netmask
  tags                                   = var.tags
  transit_gateway_id                     = module.tgw.ec2_transit_gateway_id
  vpc_cidr                               = var.connectivity_config.ingress.network.vpc_cidr
  vpc_netmask                            = var.connectivity_config.ingress.network.vpc_netmask
}

## Share the transit gateway with the other principals 
resource "aws_ram_principal_association" "associations" {
  for_each = toset(var.ram_share_principals)

  principal          = each.value
  resource_share_arn = module.tgw.ram_resource_share_id
}
