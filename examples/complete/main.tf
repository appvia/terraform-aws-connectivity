#####################################################################################
# Terraform module examples are meant to show an _example_ on how to use a module
# per use-case. The code below should not be copied directly but referenced in order
# to build your own root module that invokes this module
#####################################################################################

module "hub" {
  source = "../../"

  name                       = var.name
  amazon_side_asn            = var.asn
  description                = "The transit gateway fot all accounts within this region"
  enable_dns_support         = true
  enable_external_principals = true
  enable_multicast_support   = true
  enable_vpn_ecmp_support    = true
  ram_share_principals       = values(var.ram_principals)
  tags                       = var.tags

  connectivity_config = {
    egress = {
      network = {
        availability_zones = 2
        name               = "egress"
        private_netmask    = 24
        public_netmask     = 24
        vpc_cidr           = "10.20.0.0/21"
      }
    }

    ingress = {
      network = {
        availability_zones = 2
        name               = "ingress"
        private_netmask    = 24
        public_netmask     = 24
        vpc_cidr           = "10.20.8.0/21"
      }
    }

    trusted = {
      trusted_attachments = []
    }

    endpoints = {
      services = {
        ec2 = {
          service = "ec2"
        },
        ec2messages = {
          service = "ec2messages"
        },
        ssm = {
          service = "ssm"
        },
        ssmmessages = {
          service = "ssmmessages"
        },
      }

      sharing = {
        principals = values(var.ram_principals)
      }

      network = {
        availability_zones = 2
        name               = "endpoints"
        private_netmask    = 24
        vpc_cidr           = "10.20.16.0/21"
      }
    }
  }
}
