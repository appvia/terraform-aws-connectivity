
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

## Provision the routing table used for all shared services and management layer attachments
## Route Table: trusted
resource "aws_ec2_transit_gateway_route_table" "trusted" {
  tags               = merge(var.tags, { Name = var.connectivity_config.trusted_route_table_name })
  transit_gateway_id = module.tgw.ec2_transit_gateway_id
}

## Provision the core routing table, these are currently unused and provisioned for future expansion
## Route Table: trusted-core
resource "aws_ec2_transit_gateway_route_table" "trusted_core" {
  tags               = merge(var.tags, { Name = var.connectivity_config.trusted_core_route_table_name })
  transit_gateway_id = module.tgw.ec2_transit_gateway_id
}

## Associate the attachments with the trusted routing table.
resource "aws_ec2_transit_gateway_route_table_association" "trusted" {
  for_each = try(var.connectivity_config.trusted_attachments, {})

  replace_existing_association   = true
  transit_gateway_attachment_id  = each.value
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.trusted.id
}

## We need to add propagate the routes of the attached into the unstrusted
## routing table. This will allow traffic to flow from the unrouting table
## to the routing table.
resource "aws_ec2_transit_gateway_route_table_propagation" "untrusted" {
  for_each = var.connectivity_config.trusted_attachments

  transit_gateway_attachment_id  = each.value
  transit_gateway_route_table_id = module.tgw.ec2_transit_gateway_association_default_route_table_id
}

## We need to add a default route to the route table to egress
resource "aws_ec2_transit_gateway_route" "route_table" {
  count = local.enable_egress ? 1 : 0

  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_attachment_id  = module.egress_vpc[0].transit_gateway_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.trusted.id
}

## We add to add a default route table into the default table to the egress vpc
resource "aws_ec2_transit_gateway_route" "default" {
  count = local.enable_egress ? 1 : 0

  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_attachment_id  = module.egress_vpc[0].transit_gateway_attachment_id
  transit_gateway_route_table_id = module.tgw.ec2_transit_gateway_association_default_route_table_id
}

