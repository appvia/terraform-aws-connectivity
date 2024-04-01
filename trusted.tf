
module "trusted" {
  count  = local.enable_trusted ? 1 : 0
  source = "./modules/tgw-trusted"

  tags                               = var.tags
  transit_gateway_id                 = module.tgw.ec2_transit_gateway_id
  trusted_attachments                = var.connectivity_config.trusted.trusted_attachments
  transit_gateway_trusted_table_name = var.connectivity_config.trusted.trusted_route_table_name
}

## We add to add a default route table into the default table to the egress vpc 
resource "aws_ec2_transit_gateway_route" "trusted_default" {
  count = local.enable_trusted && local.enable_egress ? 1 : 0

  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_attachment_id  = local.egress_attachment_id
  transit_gateway_route_table_id = module.trusted[0].transit_gateway_untrusted_route_table_id
}

## We need to add a default route to the trusted route table to egress 
resource "aws_ec2_transit_gateway_route" "trusted_route_table" {
  count = local.enable_trusted && local.enable_egress ? 1 : 0

  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_attachment_id  = local.egress_attachment_id
  transit_gateway_route_table_id = module.trusted[0].transit_gateway_trusted_route_table_id
}

