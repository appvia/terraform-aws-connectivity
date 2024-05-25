
## Provision an egress vpc if required 
module "dns_vpc" {
  count   = local.enable_dns ? 1 : 0
  source  = "appvia/network/aws"
  version = "0.3.0"

  availability_zones                     = var.services.dns.network.availability_zones
  enable_default_route_table_association = local.enable_default_route_table_association
  enable_default_route_table_propagation = local.enable_default_route_table_propagation
  enable_ipam                            = var.services.dns.network.ipam_pool_id != null
  enable_transit_gateway                 = true
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
  version = "1.2.0"

  resolver_name        = var.services.dns.resolver_name
  resolver_rule_groups = var.services.dns.domain_rules
  tags                 = local.tags

  network = {
    create     = false
    name       = var.services.dns.network.name
    subnet_ids = module.dns_vpc[0].private_subnet_ids
    vpc_cidr   = module.dns_vpc[0].vpc_cidr
    vpc_id     = module.dns_vpc[0].vpc_id
  }

  depends_on = [module.dns_vpc]
}
