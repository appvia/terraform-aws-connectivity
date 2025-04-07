
## Provision an egress vpc if required
module "dns_vpc" {
  count   = local.enable_dns ? 1 : 0
  source  = "appvia/network/aws"
  version = "0.6.6"

  availability_zones                     = var.services.dns.network.availability_zones
  enable_default_route_table_association = false
  enable_default_route_table_propagation = false
  ipam_pool_id                           = var.services.dns.network.ipam_pool_id
  name                                   = var.services.dns.network.name
  private_subnet_netmask                 = var.services.dns.network.private_netmask
  tags                                   = local.tags
  transit_gateway_id                     = module.tgw.ec2_transit_gateway_id
  vpc_cidr                               = var.services.dns.network.vpc_cidr
  vpc_netmask                            = var.services.dns.network.vpc_netmask
}

## Provision if required the shared private dns
module "dns" {
  count   = local.enable_dns ? 1 : 0
  source  = "appvia/dns/aws"
  version = "1.2.5"

  resolver_name        = var.services.dns.resolver_name
  resolver_rule_groups = var.services.dns.domain_rules
  tags                 = local.tags

  network = {
    create             = false
    name               = var.services.dns.network.name
    private_subnet_ids = module.dns_vpc[0].private_subnet_ids
    vpc_cidr           = module.dns_vpc[0].vpc_cidr
    vpc_id             = module.dns_vpc[0].vpc_id
  }

  depends_on = [module.dns_vpc]
}

## Provision the association of the dns vpc with the shared routing table - we also
## need to propagation into return and core
## (DNS -> [ASSOCIATE] -> SHARED
resource "aws_ec2_transit_gateway_route_table_association" "dns_association" {
  count = local.enable_dns ? 1 : 0

  replace_existing_association   = true
  transit_gateway_attachment_id  = module.dns_vpc[0].transit_gateway_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.shared.id
}

## Provision the segregated route table entry to bypass the inspection vpc for all traffic
## to the dns
## (SEGREGATED -> [ROUTE] -> DNS)
resource "aws_ec2_transit_gateway_route" "dns_segegrated" {
  count = local.enable_dns ? 1 : 0

  destination_cidr_block         = module.dns_vpc[0].vpc_cidr
  transit_gateway_attachment_id  = module.dns_vpc[0].transit_gateway_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.segregated.id
}

## Propagate into the core routing table
## (DNS -> [PROPAGATE] -> CORE)
resource "aws_ec2_transit_gateway_route_table_propagation" "dns_core" {
  count = local.enable_dns == true ? 1 : 0

  transit_gateway_attachment_id  = module.dns_vpc[0].transit_gateway_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.core.id
}

## Propagate into the shared routing table
## (DNS -> [PROPAGATE] -> RETURN)
resource "aws_ec2_transit_gateway_route_table_propagation" "dns_return" {
  count = local.enable_dns == true ? 1 : 0

  transit_gateway_attachment_id  = module.dns_vpc[0].transit_gateway_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.return.id
}

## Propagate into the shared route table
## (DNS -> [PROPAGATE] -> SHARED)
resource "aws_ec2_transit_gateway_route_table_propagation" "dns_shared" {
  count = local.enable_dns == true ? 1 : 0

  transit_gateway_attachment_id  = module.dns_vpc[0].transit_gateway_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.shared.id
}

