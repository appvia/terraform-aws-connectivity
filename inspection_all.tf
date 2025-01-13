
# Note, this implementation creates two routing tables, return and spokes. Post creation of the spokes routing table, you must 
# associate the correct routing table with the transi gateway; currently this must be done manually.
#
# - The transit gateway must be configured so that the default association table is the `inspection-inbound` routing table
# - The transit gateway must be configured so that the default propagation table is the `inspection-return` routing table
#

## Provision the inspection vpcs if required 
module "inspection_vpc" {
  count   = local.enable_inspection_all ? 1 : 0
  source  = "appvia/network/aws"
  version = "0.3.4"

  availability_zones                     = var.connectivity_config.inspection_with_all.network.availability_zones
  enable_default_route_table_association = false
  enable_default_route_table_propagation = false
  enable_transit_gateway                 = true
  enable_transit_gateway_appliance_mode  = true
  name                                   = var.connectivity_config.inspection_with_all.network.name
  private_subnet_netmask                 = var.connectivity_config.inspection_with_all.network.private_netmask
  tags                                   = var.tags
  transit_gateway_id                     = module.tgw.ec2_transit_gateway_id
  vpc_cidr                               = var.connectivity_config.inspection_with_all.network.vpc_cidr
}

## We create a route table for all the spokes to propagated into. This route table is associated with 
## the inspection vpc attachment, and is used to return traffic to the spoke vpcs.
resource "aws_ec2_transit_gateway_route_table" "inspection_return" {
  count = local.enable_inspection_all ? 1 : 0

  tags               = merge(var.tags, { Name = var.connectivity_config.inspection_with_all.return_route_table_name })
  transit_gateway_id = module.tgw.ec2_transit_gateway_id
}

#
## Setup the association the inspection vpc, and ensure the inbound route table has a default route to the inspection vpc.
#

## We need to associated the inspection vpc attachment with the return route table.
resource "aws_ec2_transit_gateway_route_table_association" "inspection_inbound" {
  count = local.enable_inspection_all ? 1 : 0

  replace_existing_association   = true
  transit_gateway_attachment_id  = module.inspection_vpc[0].transit_gateway_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.inspection_return[0].id
}

## The default route table is setup as the default association for all attachments; we need to 
## add an default route here to funnel all traffic to the inspection vpc.
resource "aws_ec2_transit_gateway_route" "inspection_inbound" {
  count = local.enable_inspection_all ? 1 : 0

  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_attachment_id  = module.inspection_vpc[0].transit_gateway_attachment_id
  transit_gateway_route_table_id = module.tgw.ec2_transit_gateway_association_default_route_table_id
}

#
## Next, we need to ensure the various service associations and propagations - here setup the 
## routing for the services, i.e ingress, egress, endpoints
#

## If the egress vpc is enabled, we need to add a default route to the return traffic routing table, 
## to allow traffic to egress via it.
resource "aws_ec2_transit_gateway_route" "inspection_egress" {
  count = local.enable_inspection_all && local.enable_egress ? 1 : 0

  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_attachment_id  = module.egress_vpc[0].transit_gateway_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.inspection_return[0].id
}

## ENDPOINTS (association and propagation)

## We need to associate the endpoints vpc and propagate the routes
resource "aws_ec2_transit_gateway_route_table_association" "inspection_endpoints" {
  count = local.enable_inspection_all == true && local.enable_endpoints == true ? 1 : 0

  replace_existing_association   = true
  transit_gateway_attachment_id  = local.endpoints_vpc_attachment_id
  transit_gateway_route_table_id = module.tgw.ec2_transit_gateway_association_default_route_table_id
}

## We need to propagate the endpoints_vpc into the return route table
resource "aws_ec2_transit_gateway_route_table_propagation" "inspection_endpoints" {
  count = local.enable_inspection_all == true && local.enable_endpoints == true ? 1 : 0

  transit_gateway_attachment_id  = local.endpoints_vpc_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.inspection_return[0].id
}

## INGRESS (association and propagation)

## We need to associate the ingress vpc with inbound routing table
resource "aws_ec2_transit_gateway_route_table_association" "inspection_ingress" {
  count = local.enable_inspection_all == true && local.enable_ingress == true ? 1 : 0

  replace_existing_association   = true
  transit_gateway_attachment_id  = module.ingress_vpc[0].transit_gateway_attachment_id
  transit_gateway_route_table_id = module.tgw.ec2_transit_gateway_association_default_route_table_id
}

## We need to propagate the ingress_vpc into the return route table 
resource "aws_ec2_transit_gateway_route_table_propagation" "inspection_ingress" {
  count = local.enable_inspection_all == true && local.enable_ingress == true ? 1 : 0

  transit_gateway_attachment_id  = module.ingress_vpc[0].transit_gateway_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.inspection_return[0].id
}

## EGRESS (association and propagation)

## We need to associate the egress vpc with the inbound routing table
resource "aws_ec2_transit_gateway_route_table_association" "inspection_egress" {
  count = local.enable_inspection_all == true && local.enable_egress == true ? 1 : 0

  replace_existing_association   = true
  transit_gateway_attachment_id  = module.egress_vpc[0].transit_gateway_attachment_id
  transit_gateway_route_table_id = module.tgw.ec2_transit_gateway_association_default_route_table_id
}

## We need to propagate the egress_vpc into the return route spokes_route_table_name
resource "aws_ec2_transit_gateway_route_table_propagation" "inspection_egress" {
  count = local.enable_inspection_all == true && local.enable_egress == true ? 1 : 0

  transit_gateway_attachment_id  = module.egress_vpc[0].transit_gateway_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.inspection_return[0].id
}
