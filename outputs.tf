
output "connectivity_type" {
  description = "The type of connectivity for the transit gateway."
  value       = var.connectivity_config
}

output "egress_vpc_id" {
  description = "The ID of the VPC that is used for egress traffic."
  value       = local.enable_egress_creation ? module.egress_vpc.vpc_id : null
}

output "egress_vpc_private_subnet_attributes_by_az" {
  description = "The attributes of the egress VPC."
  value       = local.enable_egress_creation ? module.egress_vpc.private_subnet_attributes_by_az : null
}

output "egress_vpc_public_subnet_attributes_by_az" {
  description = "The attributes of the egress VPC."
  value       = local.enable_egress_creation ? module.egress_vpc.public_subnet_attributes_by_az : null
}

output "egress_vpc_id_rt_attributes_by_type_by_az" {
  description = "The route table attributes of the egress VPC."
  value       = local.enable_egress_creation ? module.egress_vpc.rt_attributes_by_type_by_az : null
}

output "ingress_vpc_id" {
  description = "The ID of the VPC that is used for ingress traffic."
  value       = local.enable_ingress_creation ? module.ingress_vpc.vpc_id : null
}

output "ingress_vpc_private_subnet_attributes_by_az" {
  description = "The attributes of the ingress VPC."
  value       = local.enable_ingress_creation ? module.ingress_vpc.private_subnet_attributes_by_az : null
}

output "ingress_vpc_public_subnet_attributes_by_az" {
  description = "The attributes of the ingress VPC."
  value       = local.enable_ingress_creation ? module.ingress_vpc.public_subnet_attributes_by_az : null
}

output "ingress_vpc_id_rt_attributes_by_type_by_az" {
  description = "The route table attributes of the ingress VPC."
  value       = local.enable_ingress_creation ? module.ingress_vpc.rt_attributes_by_type_by_az : null
}

output "inspection_vpc_id" {
  description = "The ID of the VPC that is used for inspection traffic."
  value       = local.enable_inspection_vpc_creation ? module.inspection_vpc.vpc_id : null
}

output "inspection_vpc_private_subnet_attributes_by_az" {
  description = "The attributes of the inspection VPC."
  value       = local.enable_inspection_vpc_creation ? module.inspection_vpc.private_subnet_attributes_by_az : null
}

output "inspection_vpc_public_subnet_attributes_by_az" {
  description = "The attributes of the inspection VPC."
  value       = local.enable_inspection_vpc_creation ? module.inspection_vpc.public_subnet_attributes_by_az : null
}

output "inspection_vpc_id_rt_attributes_by_type_by_az" {
  description = "The route table attributes of the inspection VPC."
  value       = local.enable_inspection_vpc_creation ? module.inspection_vpc.rt_attributes_by_type_by_az : null
}

output "transit_gateway_id" {
  description = "The ID of the transit gateway."
  value       = module.tgw.ec2_transit_gateway_id
}
