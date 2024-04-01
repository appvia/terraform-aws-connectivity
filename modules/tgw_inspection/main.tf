
## Lookup the transit gateway 
data "aws_ec2_transit_gateway" "current" {
  filter {
    name   = "transit-gateway-id"
    values = [var.transit_gateway_id]
  }
}

## Inbound is the default route table which all attachments should be 
## associated with. This can be setup in the console, as no api exists to 
## set the default route table.
resource "aws_ec2_transit_gateway_route_table" "inbound" {
  tags               = merge(var.tags, { Name = var.transit_gateway_inbound_table_name })
  transit_gateway_id = data.aws_ec2_transit_gateway.current.id
}

## Associate the inspection vpc with the inspection routing table
resource "aws_ec2_transit_gateway_route_table_association" "inbound" {
  replace_existing_association   = true
  transit_gateway_attachment_id  = var.attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.inbound.id
}

## We add a route into the routing table to send all traffic to the inspection vpc. 
## This is the default route table for all attachments, thus forcing all traffic to 
## be filtered.
resource "aws_ec2_transit_gateway_route" "inbound" {
  count = var.attachment_id != "" ? 1 : 0

  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_attachment_id  = var.attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.inbound.id
}

# Note: the default route table MUST be set at the default route table within the
# transit gateway console.
resource "aws_ec2_transit_gateway_route_table" "return" {
  tags               = merge(var.tags, { Name = var.transit_gateway_return_table_name })
  transit_gateway_id = data.aws_ec2_transit_gateway.current.id
}


