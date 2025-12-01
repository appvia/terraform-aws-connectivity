
## Provision an ingress vpc if required
module "ingress_vpc" {
  count   = local.enable_ingress ? 1 : 0
  source  = "appvia/network/aws"
  version = "0.6.14"

  availability_zones                     = var.services.ingress.network.availability_zones
  enable_default_route_table_association = false
  enable_default_route_table_propagation = false
  ipam_pool_id                           = var.services.ingress.network.ipam_pool_id
  name                                   = var.services.ingress.network.name
  private_subnet_netmask                 = var.services.ingress.network.private_netmask
  public_subnet_netmask                  = var.services.ingress.network.public_netmask
  tags                                   = var.tags
  transit_gateway_id                     = module.tgw.ec2_transit_gateway_id
  vpc_cidr                               = var.services.ingress.network.vpc_cidr
  vpc_netmask                            = var.services.ingress.network.vpc_netmask
}

## Associate the ingress vpc with the shared routing table, it should be able to see all networks
## attachment to the transit gateway
## (INGRESS -> [ASSOCIATE] -> RETURN)
resource "aws_ec2_transit_gateway_route_table_association" "ingress_association" {
  count = local.enable_ingress ? 1 : 0

  replace_existing_association   = true
  transit_gateway_attachment_id  = module.ingress_vpc[0].transit_gateway_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.shared.id
}

## Provision a route into the segregation table for ingress
## (RETURN -> [ROUTE] -> INGRESS)
resource "aws_ec2_transit_gateway_route" "ingress_segregated" {
  count = local.enable_ingress ? 1 : 0

  destination_cidr_block         = module.ingress_vpc[0].vpc_cidr
  transit_gateway_attachment_id  = module.ingress_vpc[0].transit_gateway_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.segregated.id
}

## Propagate into the core routing table
## (CORE -> [PROPAGATE] -> INGRESS)
resource "aws_ec2_transit_gateway_route_table_propagation" "core_ingress" {
  count = local.enable_ingress == true ? 1 : 0

  transit_gateway_attachment_id  = module.ingress_vpc[0].transit_gateway_attachment_id
  transit_gateway_route_table_id = module.tgw.ec2_transit_gateway_association_default_route_table_id
}

## Propagate into the return routing table
## (INGRESS -> [PROPAGATE] -> RETURN
resource "aws_ec2_transit_gateway_route_table_propagation" "return_ingress" {
  count = local.enable_ingress == true ? 1 : 0

  transit_gateway_attachment_id  = module.ingress_vpc[0].transit_gateway_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.return.id
}

## Propagate into the shared route table
## (INGRESS -> [PROPAGATE] -> SHARED
resource "aws_ec2_transit_gateway_route_table_propagation" "shared_ingress" {
  count = local.enable_ingress == true ? 1 : 0

  transit_gateway_attachment_id  = module.ingress_vpc[0].transit_gateway_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.shared.id
}
