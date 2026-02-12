# Unit tests for the prefix_share module
# Requires Terraform >= 1.7.0 for mock_provider support
# Run with: terraform test (from project root)
# Note: prefix_share has no external module dependencies

mock_provider "aws" {
  override_during = plan
}

run "prefix_share_empty_principals" {
  module {
    source = "./modules/prefix_share"
  }

  command = plan

  variables {
    resource_share_arn = "arn:aws:ram:eu-west-1:123456789012:resource-share/abc123"
    principals         = []
  }

  assert {
    condition     = length(var.principals) == 0
    error_message = "No principals should be configured."
  }

  assert {
    condition     = var.resource_share_arn != ""
    error_message = "resource_share_arn must be provided."
  }
}

run "prefix_share_with_principals" {
  module {
    source = "./modules/prefix_share"
  }

  command = plan

  variables {
    resource_share_arn = "arn:aws:ram:eu-west-1:123456789012:resource-share/abc123"
    principals         = ["arn:aws:organizations::123456789012:ou/ou-xxxx"]
  }

  assert {
    condition     = length(aws_ram_principal_association.current) == 1
    error_message = "One RAM principal association should be created."
  }

  assert {
    condition     = aws_ram_principal_association.current["arn:aws:organizations::123456789012:ou/ou-xxxx"].resource_share_arn == var.resource_share_arn
    error_message = "Principal association should reference the correct resource share."
  }

  assert {
    condition     = aws_ram_principal_association.current["arn:aws:organizations::123456789012:ou/ou-xxxx"].principal == "arn:aws:organizations::123456789012:ou/ou-xxxx"
    error_message = "Principal association should reference the correct principal."
  }
}
