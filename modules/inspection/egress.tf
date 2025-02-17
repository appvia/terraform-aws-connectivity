
## Provision an egress vpc if required
module "egress_vpc" {
  count   = local.enable_egress ? 1 : 0
  source  = "appvia/network/aws"
  version = "0.3.6"

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

## Associate the egress vpc with the shared routing table
## (EGRESS -> [ASSOCIATE] -> RETURN)
resource "aws_ec2_transit_gateway_route_table_association" "egress_association" {
  count = local.enable_egress ? 1 : 0

  replace_existing_association   = true
  transit_gateway_attachment_id  = module.egress_vpc[0].transit_gateway_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.shared.id
}

## Provision the association of the egress vpc
## (EGRESS -> [ROUTE] -> RETURN)
resource "aws_ec2_transit_gateway_route" "inspection_egress" {
  count = local.enable_egress ? 1 : 0

  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_attachment_id  = module.egress_vpc[0].transit_gateway_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.return.id
}

## Propagate into the core routing table
## (EGRESS -> [PROPAGATE] -> CORE)
resource "aws_ec2_transit_gateway_route_table_propagation" "core_egress" {
  count = local.enable_egress == true ? 1 : 0

  transit_gateway_attachment_id  = module.egress_vpc[0].transit_gateway_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.core.id
}

## Propagate into the return routing table
## (EGRESS -> [PROPAGATE] -> RETURN)
resource "aws_ec2_transit_gateway_route_table_propagation" "return_egress" {
  count = local.enable_egress == true ? 1 : 0

  transit_gateway_attachment_id  = module.egress_vpc[0].transit_gateway_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.return.id
}

## Propagate into the shared route table
## (EGRESS -> [PROPAGATE] -> SHARED
resource "aws_ec2_transit_gateway_route_table_propagation" "shared_egress" {
  count = local.enable_egress == true ? 1 : 0

  transit_gateway_attachment_id  = module.egress_vpc[0].transit_gateway_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.shared.id
}
