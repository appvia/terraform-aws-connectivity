
output "connectivity_type" {
  description = "The type of connectivity for the transit gateway."
  value       = var.connectivity_config
}

output "transit_gateway_id" {
  description = "The ID of the transit gateway."
  value       = module.tgw.ec2_transit_gateway_id
}
