
output "connectivity_type" {
  description = "The type of connectivity for the transit gateway."
  value       = var.connectivity_config
}

output "trusted_route_table_id" {
  description = "The ID of the trusted route table."
  value       = local.enable_trusted ? aws_ec2_transit_gateway_route_table.trusted[0].id : null
}

output "trusted_core_route_table_id" {
  description = "The ID of the trusted core route table."
  value       = local.enable_trusted ? aws_ec2_transit_gateway_route_table.trusted_core[0].id : null
}

output "workloads_route_table_id" {
  description = "The ID of the workloads route table."
  value       = local.enable_trusted ? module.tgw.ec2_transit_gateway_association_default_route_table_id : null
}

output "inspection_route_inbound_table_id" {
  description = "The ID of the inbound route table for inspection."
  value       = local.enable_inspection_all ? aws_ec2_transit_gateway_route_table.inspection_return[0].id : null
}

output "egress_vpc_id" {
  description = "The ID of the VPC that is used for egress traffic."
  value       = local.enable_egress ? module.egress_vpc[0].vpc_id : null
}

output "egress_vpc_private_subnet_attributes_by_az" {
  description = "The attributes of the egress VPC."
  value       = local.enable_egress ? module.egress_vpc[0].private_subnet_attributes_by_az : null
}

output "egress_vpc_public_subnet_attributes_by_az" {
  description = "The attributes of the egress VPC."
  value       = local.enable_egress ? module.egress_vpc[0].public_subnet_attributes_by_az : null
}

output "egress_vpc_id_rt_attributes_by_type_by_az" {
  description = "The route table attributes of the egress VPC."
  value       = local.enable_egress ? module.egress_vpc[0].rt_attributes_by_type_by_az : null
}

output "ingress_vpc_id" {
  description = "The ID of the VPC that is used for ingress traffic."
  value       = local.enable_ingress ? module.ingress_vpc[0].vpc_id : null
}

output "ingress_vpc_private_subnet_attributes_by_az" {
  description = "The attributes of the ingress VPC."
  value       = local.enable_ingress ? module.ingress_vpc[0].private_subnet_attributes_by_az : null
}

output "ingress_vpc_public_subnet_attributes_by_az" {
  description = "The attributes of the ingress VPC."
  value       = local.enable_ingress ? module.ingress_vpc[0].public_subnet_attributes_by_az : null
}

output "ingress_vpc_id_rt_attributes_by_type_by_az" {
  description = "The route table attributes of the ingress VPC."
  value       = local.enable_ingress ? module.ingress_vpc[0].rt_attributes_by_type_by_az : null
}

output "endpoints_vpc_id" {
  description = "The ID of the VPC that is used for endpoint traffic."
  value       = local.enable_endpoints ? module.endpoints[0].vpc_id : null
}

output "endpoints_vpc_private_subnet_attributes_by_az" {
  description = "The attributes of the endpoints VPC."
  value       = local.enable_endpoints ? module.endpoints[0].private_subnet_attributes_by_az : null
}

output "endpoints_vpc_id_rt_attributes_by_type_by_az" {
  description = "The route table attributes of the endpoints VPC."
  value       = local.enable_endpoints ? module.endpoints[0].rt_attributes_by_type_by_az : null
}

output "inspection_vpc_id" {
  description = "The ID of the VPC that is used for inspection traffic."
  value       = local.enable_inspection_all ? module.inspection_vpc[0].vpc_id : null
}

output "inspection_vpc_private_subnet_attributes_by_az" {
  description = "The attributes of the inspection VPC."
  value       = local.enable_inspection_all ? module.inspection_vpc[0].private_subnet_attributes_by_az : null
}

output "inspection_vpc_public_subnet_attributes_by_az" {
  description = "The attributes of the inspection VPC."
  value       = local.enable_inspection_all ? module.inspection_vpc[0].public_subnet_attributes_by_az : null
}

output "inspection_vpc_id_rt_attributes_by_type_by_az" {
  description = "The route table attributes of the inspection VPC."
  value       = local.enable_inspection_all ? module.inspection_vpc[0].rt_attributes_by_type_by_az : null
}

output "transit_gateway_id" {
  description = "The ID of the transit gateway."
  value       = module.tgw.ec2_transit_gateway_id
}
