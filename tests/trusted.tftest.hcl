# Unit tests for the trusted module
# Requires Terraform >= 1.7.0 for mock_provider support
# Run with: terraform test (from project root)
# Note: Run `make init` first (requires network access for module dependencies)

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

# Override route table resources so their IDs are known during plan
override_resource {
  target          = aws_ec2_transit_gateway_route_table.trusted
  override_during = plan
  values = {
    id = "tgw-rtb-trusted123"
  }
}

override_resource {
  target          = aws_ec2_transit_gateway_route_table.trusted_core
  override_during = plan
  values = {
    id = "tgw-rtb-trustedcore123"
  }
}

run "trusted_basic" {
  module {
    source = "./modules/trusted"
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
      "Test"        = "trusted"
    }

    connectivity_config = {
      trusted_attachments = {}
    }
  }

  assert {
    condition     = output.transit_gateway_id != ""
    error_message = "transit_gateway_id output should be set."
  }

  assert {
    condition     = output.trusted_route_table_id != ""
    error_message = "trusted_route_table_id output should be set."
  }

  assert {
    condition     = output.trusted_core_route_table_id != ""
    error_message = "trusted_core_route_table_id output should be set."
  }

  assert {
    condition     = aws_ec2_transit_gateway_route_table.trusted.transit_gateway_id == output.transit_gateway_id
    error_message = "trusted route table should be associated with the transit gateway."
  }
}

run "trusted_with_attachments" {
  module {
    source = "./modules/trusted"
  }

  command = plan

  variables {
    name                       = "test-tgw"
    description                = "Unit test transit gateway"
    amazon_side_asn            = 64512
    enable_dns_support         = true
    enable_external_principals = true
    tags = {
      "Environment" = "test"
    }

    connectivity_config = {
      trusted_attachments = {
        "ci-monitoring" = "tgw-attach-0123456789abcdef0"
      }
    }
  }

  assert {
    condition     = output.transit_gateway_id != ""
    error_message = "transit_gateway_id output should be set."
  }

  assert {
    condition     = output.trusted_route_table_id != ""
    error_message = "trusted_route_table_id output should be set."
  }

  assert {
    condition     = length(aws_ec2_transit_gateway_route_table_association.trusted) == 1
    error_message = "One trusted attachment association should be created."
  }

  assert {
    condition     = aws_ec2_transit_gateway_route_table_association.trusted["ci-monitoring"].transit_gateway_attachment_id == "tgw-attach-0123456789abcdef0"
    error_message = "Trusted association should reference the correct attachment."
  }

  assert {
    condition     = length(aws_ec2_transit_gateway_route_table_propagation.untrusted) == 1
    error_message = "One untrusted propagation should be created for bi-directional routing."
  }
}
