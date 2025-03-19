
## Provision an egress vpc if required
module "egress_vpc" {
  count = local.enable_egress ? 1 : 0
  #source  = "appvia/network/aws"
  #version = "0.3.5"
  source = "github.com/appvia/terraform-aws-network.git?ref=develop"

  availability_zones                     = var.services.egress.network.availability_zones
  enable_default_route_table_association = false
  enable_default_route_table_propagation = false
  enable_ipam                            = var.services.egress.network.ipam_pool_id != null
  enable_nat_gateway                     = true
  enable_transit_gateway                 = true
  enable_transit_gateway_subnet_natgw    = true
  ipam_pool_id                           = var.services.egress.network.ipam_pool_id
  name                                   = var.services.egress.network.name
  nat_gateway_mode                       = "all_azs"
  private_subnet_netmask                 = var.services.egress.network.private_netmask
  public_subnet_netmask                  = var.services.egress.network.public_netmask
  tags                                   = var.tags
  transit_gateway_id                     = module.tgw.ec2_transit_gateway_id
  transit_gateway_routes                 = var.services.egress.network.transit_gateway_routes
  vpc_cidr                               = var.services.egress.network.vpc_cidr
  vpc_netmask                            = var.services.egress.network.vpc_netmask
}

## We need to propagate the egress vpc into the trusted route table
resource "aws_ec2_transit_gateway_route_table_propagation" "trusted_egress" {
  count = local.enable_egress == true ? 1 : 0

  transit_gateway_attachment_id  = module.egress_vpc[0].transit_gateway_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.trusted.id
}

## We need to propagate the egress_vpc into the untrusted route table
resource "aws_ec2_transit_gateway_route_table_propagation" "untrusted_egress" {
  count = local.enable_egress == true ? 1 : 0

  transit_gateway_attachment_id  = module.egress_vpc[0].transit_gateway_attachment_id
  transit_gateway_route_table_id = module.tgw.ec2_transit_gateway_association_default_route_table_id
}

## We need to associate the egress vpc with the trusted routing table
resource "aws_ec2_transit_gateway_route_table_association" "trusted_egress" {
  count = local.enable_egress == true ? 1 : 0

  replace_existing_association   = true
  transit_gateway_attachment_id  = module.egress_vpc[0].transit_gateway_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.trusted.id
}

