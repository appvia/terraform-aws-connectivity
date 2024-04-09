
locals {
  ## If inspection is enabled we need get the attachment id for the inspection vpc
  inspection_attachment_id = local.enable_inspection ? coalesce(var.connectivity_config.inspection.attachment_id, module.inspection_vpc[0].transit_gateway_attachment_id) : null
}

## Provision the inspection vpcs if required 
module "inspection_vpc" {
  count   = local.enable_inspection_vpc_creation ? 1 : 0
  source  = "appvia/network/aws"
  version = "0.1.3"

  availability_zones                    = var.connectivity_config.inspection.network.availability_zones
  enable_transit_gateway                = true
  enable_transit_gateway_appliance_mode = true
  name                                  = var.connectivity_config.inspection.network.name
  private_subnet_netmask                = var.connectivity_config.inspection.network.private_netmask
  public_subnet_netmask                 = var.connectivity_config.inspection.network.public_netmask
  tags                                  = var.tags
  transit_gateway_id                    = module.tgw.ec2_transit_gateway_id
  vpc_cidr                              = var.connectivity_config.inspection.network.vpc_cidr
}

## Provision the inspection layout when required 
module "inspection" {
  count  = local.enable_inspection ? 1 : 0
  source = "./modules/tgw_inspection"

  attachment_id                      = local.inspection_attachment_id
  tags                               = var.tags
  transit_gateway_return_table_name  = var.connectivity_config.inspection.spokes_route_table_name
  transit_gateway_inbound_table_name = var.connectivity_config.inspection.inbound_route_table_name
  transit_gateway_id                 = module.tgw.ec2_transit_gateway_id
}

## We add to add a default route into the spokes (return) route table to egress via the egress vpc 
resource "aws_ec2_transit_gateway_route" "inspection_egress" {
  count = local.enable_inspection && local.enable_egress ? 1 : 0

  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_attachment_id  = module.egress_vpc[0].transit_gateway_attachment_id
  transit_gateway_route_table_id = module.inspection[0].inbound_route_table_id
}
