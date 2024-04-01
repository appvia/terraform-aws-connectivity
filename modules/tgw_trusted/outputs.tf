
output "transit_gateway_trusted_route_table_id" {
  description = "The ID of the trusted route table associated with the transit gateway (can see all VPCs)."
  value       = aws_ec2_transit_gateway_route_table.trusted.id
}

output "transit_gateway_untrusted_route_table_id" {
  description = "The ID of the untrusted route table associated with the transit gateway (can see only the VPCs in trusted)."
  value       = local.untrusted_route_table_id
}
