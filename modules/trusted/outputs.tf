
output "trusted_route_table_id" {
  description = "The ID of the trusted route table."
  value       = aws_ec2_transit_gateway_route_table.trusted.id
}

output "trusted_core_route_table_id" {
  description = "The ID of the trusted core route table."
  value       = aws_ec2_transit_gateway_route_table.trusted_core.id
}

output "workloads_route_table_id" {
  description = "The ID of the workloads route table."
  value       = module.tgw.ec2_transit_gateway_association_default_route_table_id
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

output "endpoints_hosted_zone_ids" {
  description = "The hosted zone IDs of the endpoints."
  value       = local.enable_endpoints ? module.endpoints[0].hosted_zone : null
}

output "endpoints_vpc_private_subnet_attributes_by_az" {
  description = "The attributes of the endpoints VPC."
  value       = local.enable_endpoints ? module.endpoints[0].private_subnet_attributes_by_az : null
}

output "endpoints_vpc_id_rt_attributes_by_type_by_az" {
  description = "The route table attributes of the endpoints VPC."
  value       = local.enable_endpoints ? module.endpoints[0].rt_attributes_by_type_by_az : null
}

output "transit_gateway_id" {
  description = "The ID of the transit gateway."
  value       = module.tgw.ec2_transit_gateway_id
}

output "region" {
  description = "The AWS region in which the resources are created."
  value       = local.region
}

output "account_id" {
  description = "The AWS account ID."
  value       = local.account_id
}
