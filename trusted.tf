
## Provision a trusted routing table for the transit gateway, this table is the default table for all propagations, 
## meaning its able to see all attachments connected to the transit gateway.
resource "aws_ec2_transit_gateway_route_table" "trusted" {
  count = local.enable_trusted ? 1 : 0

  tags               = merge(var.tags, { Name = var.connectivity_config.trusted.trusted_route_table_name })
  transit_gateway_id = module.tgw.ec2_transit_gateway_id
}

## Provision a core trusted routing table for the transit gateway, this can be used for cloud to on-premises 
## connectivity, or for trusted network connectivity. 
resource "aws_ec2_transit_gateway_route_table" "trusted_core" {
  count = local.enable_trusted ? 1 : 0

  tags               = merge(var.tags, { Name = var.connectivity_config.trusted.trusted_core_route_table_name })
  transit_gateway_id = module.tgw.ec2_transit_gateway_id
}

## Associate the trusted attachments with the trusted routing table. 
resource "aws_ec2_transit_gateway_route_table_association" "trusted" {
  for_each = local.enable_trusted == true ? toset(var.connectivity_config.trusted.trusted_attachments) : toset([])

  replace_existing_association   = true
  transit_gateway_attachment_id  = each.value
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.trusted[0].id
}

## We need to propagate the routes for the trusted attachments into the trusted routing 
## table. This will allow traffic to flow from the trusted routing table to the trusted 
## routing table. 
resource "aws_ec2_transit_gateway_route_table_propagation" "trusted" {
  for_each = local.enable_trusted == true ? var.connectivity_config.trusted.trusted_attachments : {}

  transit_gateway_attachment_id  = each.value
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.trusted[0].id
}

## We need to add propagate the routes of the trusted attached into the unstrusted 
## routing table. This will allow traffic to flow from the untrusted routing table 
## to the trusted routing table.
resource "aws_ec2_transit_gateway_route_table_propagation" "untrusted" {
  for_each = local.enable_trusted == true ? var.connectivity_config.trusted.trusted_attachments : {}

  transit_gateway_attachment_id  = each.value
  transit_gateway_route_table_id = module.tgw.ec2_transit_gateway_association_default_route_table_id
}

## We need to add a default route to the trusted route table to egress 
resource "aws_ec2_transit_gateway_route" "trusted_route_table" {
  count = local.enable_trusted && local.enable_egress ? 1 : 0

  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_attachment_id  = module.egress_vpc[0].transit_gateway_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.trusted[0].id
}

## We add to add a default route table into the default table to the egress vpc 
resource "aws_ec2_transit_gateway_route" "trusted_default" {
  count = local.enable_trusted && local.enable_egress ? 1 : 0

  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_attachment_id  = module.egress_vpc[0].transit_gateway_attachment_id
  transit_gateway_route_table_id = module.tgw.ec2_transit_gateway_association_default_route_table_id
}

#
## Associations  
#

## We need to associate the endpoints vpc with the trusted routing table 
resource "aws_ec2_transit_gateway_route_table_association" "trusted_endpoints" {
  count = local.enable_trusted == true && local.enable_endpoints == true ? 1 : 0

  replace_existing_association   = true
  transit_gateway_attachment_id  = local.endpoints_vpc_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.trusted[0].id
}

## We need to associate the ingress vpc with the trusted routing table 
resource "aws_ec2_transit_gateway_route_table_association" "trusted_ingress" {
  count = local.enable_trusted == true && local.enable_ingress == true ? 1 : 0

  replace_existing_association   = true
  transit_gateway_attachment_id  = module.ingress_vpc[0].transit_gateway_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.trusted[0].id
}

## We need to associate the egress vpc with the trusted routing table 
resource "aws_ec2_transit_gateway_route_table_association" "trusted_egress" {
  count = local.enable_trusted == true && local.enable_egress == true ? 1 : 0

  replace_existing_association   = true
  transit_gateway_attachment_id  = module.egress_vpc[0].transit_gateway_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.trusted[0].id
}

#
## Propagations into the trusted routing table
#

## We need to propagate the ingress vpc into the trusted route table 
resource "aws_ec2_transit_gateway_route_table_propagation" "trusted_ingress" {
  count = local.enable_trusted == true && local.enable_ingress == true ? 1 : 0

  transit_gateway_attachment_id  = module.ingress_vpc[0].transit_gateway_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.trusted[0].id
}

## We need to propagate the egress vpc into the trusted route table  
resource "aws_ec2_transit_gateway_route_table_propagation" "trusted_egress" {
  count = local.enable_trusted == true && local.enable_egress == true ? 1 : 0

  transit_gateway_attachment_id  = module.egress_vpc[0].transit_gateway_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.trusted[0].id
}

## We need to propagate the endpoints vpc into the trusted route table
resource "aws_ec2_transit_gateway_route_table_propagation" "trusted_endpoints" {
  count = local.enable_trusted == true && local.enable_endpoints == true ? 1 : 0

  transit_gateway_attachment_id  = local.endpoints_vpc_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.trusted[0].id
}

## We need to propagate the dns vpc into the trusted route table
resource "aws_ec2_transit_gateway_route_table_propagation" "trusted_dns" {
  count = local.enable_trusted == true && local.enable_dns == true ? 1 : 0

  transit_gateway_attachment_id  = module.dns_vpc[0].transit_gateway_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.trusted[0].id
}

#
## Propagations into the untrusted routing table
#

## We need to propagate the endpoints_vpc into the untrusted route table 
resource "aws_ec2_transit_gateway_route_table_propagation" "untrusted_endpoints" {
  count = local.enable_trusted == true && local.enable_endpoints == true ? 1 : 0

  transit_gateway_attachment_id  = local.endpoints_vpc_attachment_id
  transit_gateway_route_table_id = module.tgw.ec2_transit_gateway_association_default_route_table_id
}

## We need to propagate the ingress_vpc into the untrusted route table 
resource "aws_ec2_transit_gateway_route_table_propagation" "untrusted_ingress" {
  count = local.enable_trusted == true && local.enable_ingress == true ? 1 : 0

  transit_gateway_attachment_id  = module.ingress_vpc[0].transit_gateway_attachment_id
  transit_gateway_route_table_id = module.tgw.ec2_transit_gateway_association_default_route_table_id
}

## We need to propagate the egress_vpc into the untrusted route table 
resource "aws_ec2_transit_gateway_route_table_propagation" "untrusted_egress" {
  count = local.enable_trusted == true && local.enable_egress == true ? 1 : 0

  transit_gateway_attachment_id  = module.egress_vpc[0].transit_gateway_attachment_id
  transit_gateway_route_table_id = module.tgw.ec2_transit_gateway_association_default_route_table_id
}

## We need to propagate the dns_vpc into the untrusted route table 
resource "aws_ec2_transit_gateway_route_table_propagation" "untrusted_dns" {
  count = local.enable_trusted == true && local.enable_dns == true ? 1 : 0

  transit_gateway_attachment_id  = module.dns_vpc[0].transit_gateway_attachment_id
  transit_gateway_route_table_id = module.tgw.ec2_transit_gateway_association_default_route_table_id
}
