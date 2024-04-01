
output "connectivity_type" {
  description = "The type of connectivity for the transit gateway."
  value       = var.connectivity_config
}

output "egress_vpc_id" {
  description = "The ID of the VPC that is used for egress traffic."
  value       = local.enable_egress_creation ? module.egress_vpc.vpc_id : null
}

output "ingress_vpc_id" {
  description = "The ID of the VPC that is used for ingress traffic."
  value       = local.enable_ingress_creation ? module.ingress_vpc.vpc_id : null
}

output "transit_gateway_id" {
  description = "The ID of the transit gateway."
  value       = module.tgw.ec2_transit_gateway_id
}
