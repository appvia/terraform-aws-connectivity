![Github Actions](../../actions/workflows/terraform.yml/badge.svg)

# Terraform <NAME>

## Description

Add a description of the module here

## Usage

Add example usage here

```hcl
module "example" {
  source  = "appvia/<NAME>/aws"
  version = "0.0.1"

  # insert variables here
}
```

## Update Documentation

The `terraform-docs` utility is used to generate this README. Follow the below steps to update:

1. Make changes to the `.terraform-docs.yml` file
2. Fetch the `terraform-docs` binary (https://terraform-docs.io/user-guide/installation/)
3. Run `terraform-docs markdown table --output-file ${PWD}/README.md --output-mode inject .`

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0.7 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.0.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 5.0.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_egress_vpc"></a> [egress\_vpc](#module\_egress\_vpc) | appvia/network/aws | 0.1.3 |
| <a name="module_ingress_vpc"></a> [ingress\_vpc](#module\_ingress\_vpc) | appvia/network/aws | 0.1.3 |
| <a name="module_inspection"></a> [inspection](#module\_inspection) | ./modules/tgw_inspection | n/a |
| <a name="module_share_prefixes"></a> [share\_prefixes](#module\_share\_prefixes) | ./modules/prefix_share | n/a |
| <a name="module_tgw"></a> [tgw](#module\_tgw) | terraform-aws-modules/transit-gateway/aws | 2.12.2 |
| <a name="module_trusted"></a> [trusted](#module\_trusted) | ./modules/tgw_trusted | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_ec2_managed_prefix_list.prefixes](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_managed_prefix_list) | resource |
| [aws_ec2_transit_gateway_route.inspection_egress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_transit_gateway_route) | resource |
| [aws_ec2_transit_gateway_route.trusted_default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_transit_gateway_route) | resource |
| [aws_ec2_transit_gateway_route.trusted_route_table](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_transit_gateway_route) | resource |
| [aws_ram_principal_association.associations](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ram_principal_association) | resource |
| [aws_ram_resource_association.prefixes](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ram_resource_association) | resource |
| [aws_ram_resource_share.prefixes](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ram_resource_share) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_amazon_side_asn"></a> [amazon\_side\_asn](#input\_amazon\_side\_asn) | The ASN for the transit gateway. | `number` | n/a | yes |
| <a name="input_connectivity_config"></a> [connectivity\_config](#input\_connectivity\_config) | The type of connectivity options for the transit gateway. | <pre>object({<br>    egress = optional(object({<br>      attachment_id = optional(string, "")<br>      network = optional(object({<br>        availability_zones = number<br>        ipam_pool_id       = optional(string, null)<br>        name               = optional(string, "egress")<br>        vpc_cidr           = optional(string, null)<br>        vpc_netmask        = optional(string, null)<br>      }), null)<br>    }), null)<br>    ingress = optional(object({<br>      attachment_id = optional(string, "")<br>      network = optional(object({<br>        availability_zones = number<br>        ipam_pool_id       = optional(string, null)<br>        name               = optional(string, "ingress")<br>        private_netmask    = optional(number, null)<br>        public_netmask     = optional(number, null)<br>        vpc_cidr           = optional(string, null)<br>        vpc_netmask        = optional(string, null)<br>      }), null)<br>    }), null)<br>    inspection = optional(object({<br>      attachment_id            = optional(string, "")<br>      inbound_route_table_name = optional(string, "inbound")<br>      spokes_route_table_name  = optional(string, "spokes")<br>    }), null)<br>    trusted = optional(object({<br>      trusted_attachments      = optional(list(string), [])<br>      trusted_route_table_name = optional(string, "trusted")<br>    }), null)<br>  })</pre> | n/a | yes |
| <a name="input_description"></a> [description](#input\_description) | The description of the transit gateway to provision. | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to add to all resources. | `map(string)` | n/a | yes |
| <a name="input_enable_dns_support"></a> [enable\_dns\_support](#input\_enable\_dns\_support) | Whether DNS support is enabled. | `bool` | `true` | no |
| <a name="input_enable_external_principals"></a> [enable\_external\_principals](#input\_enable\_external\_principals) | Whether to enable external principals in the RAM share. | `bool` | `true` | no |
| <a name="input_enable_multicast_support"></a> [enable\_multicast\_support](#input\_enable\_multicast\_support) | Whether multicast support is enabled. | `bool` | `false` | no |
| <a name="input_enable_vpn_ecmp_support"></a> [enable\_vpn\_ecmp\_support](#input\_enable\_vpn\_ecmp\_support) | Whether VPN Equal Cost Multipath Protocol support is enabled. | `bool` | `false` | no |
| <a name="input_name"></a> [name](#input\_name) | The name of the transit gateway to provision. | `string` | `"tgw-hub"` | no |
| <a name="input_prefix_lists"></a> [prefix\_lists](#input\_prefix\_lists) | Provides the ability to provision prefix lists, and share them with other accounts. | <pre>list(object({<br>    name = string<br>    entry = list(object({<br>      address_family = optional(string, "IPv4")<br>      cidr           = string<br>      description    = string<br>      max_entries    = number<br>    }))<br>  }))</pre> | `[]` | no |
| <a name="input_prefix_ram_principals"></a> [prefix\_ram\_principals](#input\_prefix\_ram\_principals) | The list of organizational units or accounts to share the prefix lists with. | `list(string)` | `[]` | no |
| <a name="input_ram_share_name"></a> [ram\_share\_name](#input\_ram\_share\_name) | The name of the RAM share to create for the transit gateway. | `string` | `"tgw-hub-ram-share"` | no |
| <a name="input_ram_share_principals"></a> [ram\_share\_principals](#input\_ram\_share\_principals) | The list of organizational units or accounts to share the transit gateway with. | `list(string)` | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_connectivity_type"></a> [connectivity\_type](#output\_connectivity\_type) | The type of connectivity for the transit gateway. |
| <a name="output_transit_gateway_id"></a> [transit\_gateway\_id](#output\_transit\_gateway\_id) | The ID of the transit gateway. |
<!-- END_TF_DOCS -->
