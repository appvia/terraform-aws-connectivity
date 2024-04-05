#####################################################################################
# Terraform module examples are meant to show an _example_ on how to use a module
# per use-case. The code below should not be copied directly but referenced in order
# to build your own root module that invokes this module
#####################################################################################

module "hub" {
  source = "../../"

  name                       = var.name
  description                = "The transit gateway fot all accounts within this region"
  amazon_side_asn            = var.asn
  enable_dns_support         = true
  enable_external_principals = true
  enable_multicast_support   = true
  enable_vpn_ecmp_support    = true
  tags                       = var.tags

  connectivity_config = {
    inspection = {
      ## Will be created in the hub account i.e. provider aws 
      network = {
        availability_zones = 3
        name               = "inspection"
        private_netmask    = "24"
        public_netmask     = "24"
        vpc_cidr           = "100.64.0.0/21"
      }
      #
      ## If you want to create the inspection vpc independently, create post the transit gateway creation
      ## and provide the attachment id afterwards
      # 
      # attachment_id = "tgw-attach-1234567890"
    }
  }
}
