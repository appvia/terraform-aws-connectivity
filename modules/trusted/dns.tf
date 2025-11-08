
## Provision an egress vpc if required
module "dns_vpc" {
  count   = local.enable_dns ? 1 : 0
  source  = "appvia/network/aws"
  version = "0.6.13"

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
  version = "1.2.10"

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

## We need to propagate the dns vpc into the trusted route table
resource "aws_ec2_transit_gateway_route_table_propagation" "trusted_dns" {
  count = local.enable_dns == true ? 1 : 0

  transit_gateway_attachment_id  = module.dns_vpc[0].transit_gateway_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.trusted.id
}

## We need to propagate the endpoints_vpc into the untrusted route table
resource "aws_ec2_transit_gateway_route_table_propagation" "untrusted_endpoints" {
  count = local.enable_endpoints == true ? 1 : 0

  transit_gateway_attachment_id  = local.endpoints_vpc_attachment_id
  transit_gateway_route_table_id = module.tgw.ec2_transit_gateway_association_default_route_table_id
}

