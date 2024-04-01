
## Provision the inspection layout when required 
module "inspection" {
  count  = local.enable_inspection ? 1 : 0
  source = "./modules/tgw_inspection"

  attachment_id                      = var.connectivity_config.inspection.attachment_id
  tags                               = var.tags
  transit_gateway_return_table_name  = var.connectivity_config.inspection.spokes_route_table_name
  transit_gateway_inbound_table_name = var.connectivity_config.inspection.inbound_route_table_name
  transit_gateway_id                 = module.tgw.ec2_transit_gateway_id
}

## We add to add a default route into the spokes (return) route table to egress via the egress vpc 
resource "aws_ec2_transit_gateway_route" "inspection_egress" {
  count = local.enable_inspection && local.enable_egress ? 1 : 0

  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_attachment_id  = local.egress_attachment_id
  transit_gateway_route_table_id = module.inspection[0].inbound_route_table_id
}
