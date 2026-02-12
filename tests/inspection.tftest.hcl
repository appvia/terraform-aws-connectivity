# Unit tests for the inspection module
# Requires Terraform >= 1.7.0 for mock_provider support
# Run with: terraform test (from project root)

mock_provider "aws" {
  override_during = plan
}

# Override child modules to avoid fetching external dependencies during plan
override_module {
  target          = module.tgw
  override_during = plan
  outputs = {
    ec2_transit_gateway_id                                 = "tgw-0123456789abcdef0"
    ram_resource_share_id                                  = "arn:aws:ram:eu-west-1:123456789012:resource-share/abc123"
    ec2_transit_gateway_association_default_route_table_id = "tgw-rtb-0123456789abcdef0"
  }
}

override_module {
  target          = module.inspection_vpc
  override_during = plan
  outputs = {
    transit_gateway_attachment_id   = "tgw-attach-0123456789abcdef0"
    vpc_id                          = "vpc-0123456789abcdef0"
    vpc_cidr                        = "100.64.0.0/21"
    private_subnet_attributes_by_az = {}
    public_subnet_attributes_by_az  = {}
    rt_attributes_by_type_by_az     = {}
    private_subnet_cidr_by_id       = {}
    private_subnet_ids              = []
  }
}

# Override route table resources so their IDs are known during plan
override_resource {
  target          = aws_ec2_transit_gateway_route_table.segregated
  override_during = plan
  values = {
    id = "tgw-rtb-segregated123"
  }
}

override_resource {
  target          = aws_ec2_transit_gateway_route_table.return
  override_during = plan
  values = {
    id = "tgw-rtb-return123"
  }
}

override_resource {
  target          = aws_ec2_transit_gateway_route_table.shared
  override_during = plan
  values = {
    id = "tgw-rtb-shared123"
  }
}

override_resource {
  target          = aws_ec2_transit_gateway_route_table.core
  override_during = plan
  values = {
    id = "tgw-rtb-core123"
  }
}

run "inspection_basic" {
  module {
    source = "./modules/inspection"
  }

  command = plan

  variables {
    name                       = "test-tgw"
    description                = "Unit test transit gateway"
    amazon_side_asn            = 64512
    enable_dns_support         = true
    enable_external_principals = true
    enable_multicast_support   = false
    enable_vpn_ecmp_support    = false
    tags = {
      "Environment" = "test"
      "Test"        = "inspection"
    }

    connectivity_config = {
      network = {
        availability_zones = 2
        vpc_cidr           = "100.64.0.0/21"
        name               = "inspection"
        private_netmask    = 24
        public_netmask     = 0
      }
    }
  }

  assert {
    condition     = output.transit_gateway_id != ""
    error_message = "transit_gateway_id output should be set."
  }

  assert {
    condition     = output.segregated_route_table_id != ""
    error_message = "segregated_route_table_id output should be set."
  }

  assert {
    condition     = output.return_route_table_id != ""
    error_message = "return_route_table_id output should be set."
  }

  assert {
    condition     = output.core_route_table_id != ""
    error_message = "core_route_table_id output should be set."
  }

  assert {
    condition     = output.inspection_vpc_id != ""
    error_message = "inspection_vpc_id output should be set."
  }

  assert {
    condition     = aws_ec2_transit_gateway_route_table.segregated.transit_gateway_id == output.transit_gateway_id
    error_message = "segregated route table should be associated with the transit gateway."
  }

  assert {
    condition     = aws_ec2_transit_gateway_route.segregated_default.destination_cidr_block == "0.0.0.0/0"
    error_message = "segregated_default route should target 0.0.0.0/0."
  }

  assert {
    condition     = aws_ec2_transit_gateway_route.shared_default.destination_cidr_block == "0.0.0.0/0"
    error_message = "shared_default route should target 0.0.0.0/0."
  }
}
