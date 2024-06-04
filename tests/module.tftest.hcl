mock_provider "aws" {}

run "basic" {
  command = plan

  variables {
    amazon_side_asn = 64512

    connectivity_config = {
      inspection_with_all = {
        network = {
          availability_zones     = 3
          vpc_cidr               = "100.64.0.0/21"
          name                   = "inspection"
          private_subnet_netmask = 24
          public_subnet_netmask  = 24
        }
      }

    }
    description = "The transit gateway fot all accounts within this region"
    tags = {
      "Owner"       = "Engineering",
      "Environment" = "Production",
      "Application" = "Connectivity",
    }
  }
}
