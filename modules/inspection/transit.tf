#
# Note, this implementation creates two routing tables, return and spokes. Post creation of the spokes routing table, you must
# associate the correct routing table with the transi gateway; currently this must be done manually.
#
# - The transit gateway must be configured so that the default association table is the `inspection-inbound` routing table
# - The transit gateway must be configured so that the default propagation table is the `inspection-return` routing table
#

## Provision the transit gateway for this region
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

## Provision the route table for all segregated networks - this table is used by all vpc's
## who's traffic will be filtered by the inspection vpc
resource "aws_ec2_transit_gateway_route_table" "segregated" {
  tags               = merge(var.tags, { Name = var.connectivity_config.segregated_route_table_name })
  transit_gateway_id = module.tgw.ec2_transit_gateway_id
}

## Provision the route table for all returning traffic from the inspection vpc - this
## table is by the inspection vpc to route traffic back to the originating vpc
resource "aws_ec2_transit_gateway_route_table" "return" {
  tags               = merge(var.tags, { Name = var.connectivity_config.return_route_table_name })
  transit_gateway_id = module.tgw.ec2_transit_gateway_id
}

## Provision a shared routing table for all services which need to access the inspection vpc
resource "aws_ec2_transit_gateway_route_table" "shared" {
  tags               = merge(var.tags, { Name = var.connectivity_config.shared_route_table_name })
  transit_gateway_id = module.tgw.ec2_transit_gateway_id
}

## Provision the core routing table - currently unused - this table is used for future expansion,
## and will contain for all vpcs
resource "aws_ec2_transit_gateway_route_table" "core" {
  tags               = merge(var.tags, { Name = var.connectivity_config.core_route_table_name })
  transit_gateway_id = module.tgw.ec2_transit_gateway_id
}

## Associate the inspection VPC with the return traffic routing table
## (INSPECTION -> [ASSOCIATE] -> RETURN)
resource "aws_ec2_transit_gateway_route_table_association" "inspection_association" {
  replace_existing_association   = true
  transit_gateway_attachment_id  = module.inspection_vpc.transit_gateway_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.return.id
}

## Provision the segregated routing table, this is used for all networks which are being filtered.
# (SEGREGATED -> [ROUTE] -> INSPECTION
resource "aws_ec2_transit_gateway_route" "segregated_default" {
  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_attachment_id  = module.inspection_vpc.transit_gateway_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.segregated.id
}

## Provision a default route in the shared routing table to the inspection vpc. If the shared services
## need to access external services they need to go via the inspection vpc
## (SHARED -> [ROUTE] -> INSPECTION)
resource "aws_ec2_transit_gateway_route" "shared_default" {
  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_attachment_id  = module.inspection_vpc.transit_gateway_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.shared.id
}

## Provision any CIDR ranges to blackhole the segregated route table
## (SEGREGATED -> [ROUTE] -> BLACKHOLE)
resource "aws_ec2_transit_gateway_route" "blackhole_segregated" {
  for_each = toset(var.connectivity_config.segregated_blackhole_cidrs)

  blackhole                      = true
  destination_cidr_block         = each.key
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.segregated.id
}

