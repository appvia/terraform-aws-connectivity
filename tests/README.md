# Terraform Module Tests

This directory contains unit tests for the terraform-aws-connectivity modules.

## Requirements

- **Terraform >= 1.7.0** (for `mock_provider` and `override_module` support)
- Network access for initial `terraform init` (to fetch module dependencies)

## Test Files

| File | Module | Description |
|------|--------|-------------|
| `inspection.tftest.hcl` | `modules/inspection` | Inspection layout with transit gateway and inspection VPC |
| `trusted.tftest.hcl` | `modules/trusted` | Trusted layout with transit gateway and trusted/untrusted routing |
| `prefix_share.tftest.hcl` | `modules/prefix_share` | RAM resource share principal associations (no external deps) |

## Running Tests

From the project root:

```bash
# Initialize (fetches modules and providers - requires network access)
make init

# Run all tests
make tests
```

Or directly:

```bash
terraform init -backend=false
terraform test
```

## Test Structure

Tests follow the pattern from the reference `inspection.tftest.hcl`:

- **mock_provider**: Mocks the AWS provider to avoid creating real resources
- **override_module**: Replaces child module outputs (e.g. `module.tgw`, `module.inspection_vpc`) so external dependencies are not executed during plan
- **run blocks**: Each run executes `terraform plan` with specific variables and asserts on configuration values (e.g. `var.name != ""`)

## Notes

- **inspection** and **trusted** modules have external dependencies (appvia/network, terraform-aws-modules/transit-gateway, etc.). The `override_module` blocks allow unit testing without executing those modules.
- **prefix_share** has no external module dependencies and is the simplest to test.
- The first `terraform init` may take several minutes while downloading remote modules.
