
## Provision an ingress vpc if required
module "ingress_vpc" {
  count   = local.enable_ingress ? 1 : 0
  source  = "appvia/network/aws"
  version = "0.6.9"

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

## We need to propagate the ingress vpc into the trusted route table
resource "aws_ec2_transit_gateway_route_table_propagation" "trusted_ingress" {
  count = local.enable_ingress == true ? 1 : 0

  transit_gateway_attachment_id  = module.ingress_vpc[0].transit_gateway_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.trusted.id
}

## We need to propagate the ingress_vpc into the untrusted route table
resource "aws_ec2_transit_gateway_route_table_propagation" "untrusted_ingress" {
  count = local.enable_ingress == true ? 1 : 0

  transit_gateway_attachment_id  = module.ingress_vpc[0].transit_gateway_attachment_id
  transit_gateway_route_table_id = module.tgw.ec2_transit_gateway_association_default_route_table_id
}

## We need to associate the ingress vpc with the trusted routing table
resource "aws_ec2_transit_gateway_route_table_association" "trusted_ingress" {
  count = local.enable_ingress == true ? 1 : 0

  replace_existing_association   = true
  transit_gateway_attachment_id  = module.ingress_vpc[0].transit_gateway_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.trusted.id
}

