
## Provision an egress vpc if required
module "endpoints_vpc" {
  count   = local.enable_endpoints ? 1 : 0
  source  = "appvia/network/aws"
  version = "0.4.0"

  availability_zones                     = var.services.endpoints.network.availability_zones
  enable_default_route_table_association = false
  enable_default_route_table_propagation = false
  ipam_pool_id                           = var.services.endpoints.network.ipam_pool_id
  name                                   = var.services.endpoints.network.name
  private_subnet_netmask                 = var.services.endpoints.network.private_netmask
  tags                                   = var.tags
  transit_gateway_id                     = module.tgw.ec2_transit_gateway_id
  vpc_cidr                               = var.services.endpoints.network.vpc_cidr
  vpc_netmask                            = var.services.endpoints.network.vpc_netmask
}

## Provision if required the shared private endpoints
module "endpoints" {
  count   = local.enable_endpoints ? 1 : 0
  source  = "appvia/private-endpoints/aws"
  version = "0.3.1"

  name      = var.services.endpoints.network.name
  endpoints = var.services.endpoints.services
  region    = local.region
  tags      = var.tags

  network = {
    create                    = false
    name                      = var.services.endpoints.network.name
    private_subnet_cidr_by_id = module.endpoints_vpc[0].private_subnet_cidr_by_id
    vpc_dns_resolver          = cidrhost(module.endpoints_vpc[0].vpc_cidr, 2)
    vpc_id                    = module.endpoints_vpc[0].vpc_id
  }

  resolvers = {
    outbound = {
      create            = true
      ip_address_offset = 10
    }
  }

  sharing = {
    principals = var.services.endpoints.sharing.principals
  }

  depends_on = [module.endpoints_vpc]
}

## Provision the association of the endpoints vpc with the shared routing table - we also
## need to propagation into return and core
## (ENDPOINT -> [ASSOCIATE] -> RETURN)
resource "aws_ec2_transit_gateway_route_table_association" "endpoints_association" {
  count = local.enable_endpoints ? 1 : 0

  replace_existing_association   = true
  transit_gateway_attachment_id  = module.endpoints_vpc[0].transit_gateway_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.shared.id
}

## Provision the segregated route table entry to bypass the inspection vpc for all traffic
## to the endpoints
## (SEGREGATED -> [ROUTE] -> ENDPOINTS)
resource "aws_ec2_transit_gateway_route" "endpoints_segegrated" {
  count = local.enable_endpoints ? 1 : 0

  destination_cidr_block         = module.endpoints_vpc[0].vpc_cidr
  transit_gateway_attachment_id  = module.endpoints_vpc[0].transit_gateway_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.segregated.id
}

## Propagate into the core routing table
## (ENDPOINTS -> [PROPAGATE] -> CORE
resource "aws_ec2_transit_gateway_route_table_propagation" "endpoints_core" {
  count = local.enable_endpoints == true ? 1 : 0

  transit_gateway_attachment_id  = module.endpoints_vpc[0].transit_gateway_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.core.id
}

## Propagate into the return routing table
## (ENDPOINTS -> [PROPAGATE] -> RETURN
resource "aws_ec2_transit_gateway_route_table_propagation" "endpoints_return" {
  count = local.enable_endpoints == true ? 1 : 0

  transit_gateway_attachment_id  = module.endpoints_vpc[0].transit_gateway_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.return.id
}

## Propagate into the shared route table
## (ENDPOINTS -> [PROPAGATE] -> SHARED
resource "aws_ec2_transit_gateway_route_table_propagation" "endpoints_shared" {
  count = local.enable_endpoints == true ? 1 : 0

  transit_gateway_attachment_id  = module.endpoints_vpc[0].transit_gateway_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.shared.id
}

