
locals {
  ## The untusted routing table id 
  untrusted_route_table_id = data.aws_ec2_transit_gateway.current.association_default_route_table_id
}

## Lookup the transit gateway 
data "aws_ec2_transit_gateway" "current" {
  filter {
    name   = "transit-gateway-id"
    values = [var.transit_gateway_id]
  }
}

## Provision a trusted routing table for the transit gateway, this table is the default table for all propagations, 
## meaning its able to see all attachments connected to the transit gateway.
resource "aws_ec2_transit_gateway_route_table" "trusted" {
  tags               = merge(var.tags, { Name = var.transit_gateway_trusted_table_name })
  transit_gateway_id = data.aws_ec2_transit_gateway.current.id
}

## Associate the trusted attachments with the trusted routing table. 
resource "aws_ec2_transit_gateway_route_table_association" "trusted" {
  for_each = toset(var.trusted_attachments)

  replace_existing_association   = true
  transit_gateway_attachment_id  = each.value
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.trusted.id
}

## We need to add propagate the routes of the trusted attached into the unstrusted 
## routing table. This will allow traffic to flow from the untrusted routing table 
## to the trusted routing table.
resource "aws_ec2_transit_gateway_route_table_propagation" "untrusted" {
  for_each = toset(var.trusted_attachments)

  transit_gateway_attachment_id  = each.value
  transit_gateway_route_table_id = local.untrusted_route_table_id
}
