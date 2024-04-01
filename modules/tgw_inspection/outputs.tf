output "inbound_route_table_id" {
  description = "The ID of the route table associated with the inbound traffic to inspection vpc"
  value       = aws_ec2_transit_gateway_route_table.inbound.id
}

output "return_route_table_id" {
  description = "The ID of the route table associated with the return traffic"
  value       = aws_ec2_transit_gateway_route_table.return.id
}
