
## Provision the inspection vpcs if required 
module "inspection_vpc" {
  count   = local.enable_inspection ? 1 : 0
  source  = "appvia/network/aws"
  version = "0.1.6"

  availability_zones                     = var.connectivity_config.inspection.network.availability_zones
  enable_default_route_table_association = false
  enable_default_route_table_propagation = false
  enable_transit_gateway                 = true
  enable_transit_gateway_appliance_mode  = true
  name                                   = var.connectivity_config.inspection.network.name
  private_subnet_netmask                 = var.connectivity_config.inspection.network.private_netmask
  tags                                   = var.tags
  transit_gateway_id                     = module.tgw.ec2_transit_gateway_id
  vpc_cidr                               = var.connectivity_config.inspection.network.vpc_cidr
}

## We create a route table for all the spokes to propagatio into. This route table is associated with 
## the inspection vpc attachment, and is used to return traffic to the spoke vpcs.
resource "aws_ec2_transit_gateway_route_table" "inspection_return" {
  count = local.enable_inspection ? 1 : 0

  tags               = merge(var.tags, { Name = var.connectivity_config.inspection.spokes_route_table_name })
  transit_gateway_id = module.tgw.ec2_transit_gateway_id
}

## We need to associated the inspection vpc attachment with the return route table.
resource "aws_ec2_transit_gateway_route_table_association" "inspection_inbound" {
  count = local.enable_inspection ? 1 : 0

  replace_existing_association   = true
  transit_gateway_attachment_id  = module.inspection_vpc[0].transit_gateway_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.inspection_return[0].id
}

## The default route table is setup as the default association for all attachments; we need to 
## add an default route here to funnel all traffic to the inspection vpc.
resource "aws_ec2_transit_gateway_route" "inspection_inbound" {
  count = local.enable_inspection ? 1 : 0

  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_attachment_id  = module.inspection_vpc[0].transit_gateway_attachment_id
  transit_gateway_route_table_id = module.tgw.ec2_transit_gateway_association_default_route_table_id
}

## If the egress vpc is enabled, we need to add a default route to the return traffic routing table, 
## to allow traffic to egress via it.
resource "aws_ec2_transit_gateway_route" "inspection_egress" {
  count = local.enable_inspection && local.enable_egress ? 1 : 0

  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_attachment_id  = module.egress_vpc[0].transit_gateway_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.inspection_return[0].id
}

## We need to associate the endpoints vpc   
resource "aws_ec2_transit_gateway_route_table_association" "inspection_endpoints" {
  count = local.enable_inspection == true && local.enable_endpoints == true ? 1 : 0

  replace_existing_association   = true
  transit_gateway_attachment_id  = module.endpoints_vpc[0].transit_gateway_attachment_id
  transit_gateway_route_table_id = module.tgw.ec2_transit_gateway_association_default_route_table_id
}

## We need to associate the ingress vpc 
resource "aws_ec2_transit_gateway_route_table_association" "inspection_ingress" {
  count = local.enable_inspection == true && local.enable_ingress == true ? 1 : 0

  replace_existing_association   = true
  transit_gateway_attachment_id  = module.ingress_vpc[0].transit_gateway_attachment_id
  transit_gateway_route_table_id = module.tgw.ec2_transit_gateway_association_default_route_table_id
}

## We need to associate the egress vpc 
resource "aws_ec2_transit_gateway_route_table_association" "inspection_egress" {
  count = local.enable_inspection == true && local.enable_egress == true ? 1 : 0

  replace_existing_association   = true
  transit_gateway_attachment_id  = module.egress_vpc[0].transit_gateway_attachment_id
  transit_gateway_route_table_id = module.tgw.ec2_transit_gateway_association_default_route_table_id
}

## We need to propagate the endpoints_vpc into the return route table 
resource "aws_ec2_transit_gateway_route_table_propagation" "inspection_endpoints" {
  count = local.enable_inspection == true && local.enable_endpoints == true ? 1 : 0

  transit_gateway_attachment_id  = module.endpoints_vpc[0].transit_gateway_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.inspection_return[0].id
}

## We need to propagate the ingress_vpc into the return route table 
resource "aws_ec2_transit_gateway_route_table_propagation" "inspection_ingress" {
  count = local.enable_inspection == true && local.enable_ingress == true ? 1 : 0

  transit_gateway_attachment_id  = module.ingress_vpc[0].transit_gateway_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.inspection_return[0].id
}

## We need to propagate the egress_vpc into the return route spokes_route_table_name
resource "aws_ec2_transit_gateway_route_table_propagation" "inspection_egress" {
  count = local.enable_inspection == true && local.enable_egress == true ? 1 : 0

  transit_gateway_attachment_id  = module.egress_vpc[0].transit_gateway_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.inspection_return[0].id
}
