![Github Actions](../../actions/workflows/terraform.yml/badge.svg)

# Terraform AWS Connectivity Module

## Description

The purpose of this module is to provision the necessary resources to establish connectivity between a transit gateway and other VPCs, accounts, and on-premises networks, as well as provision a baseline for network topology and security. Currently this module can setup the requirement for

- Inspection VPC: provision the necessary resources and routing to inspect traffic between the transit gateway and spoke VPCs.
- Trusted Layout: here the routing is broken into two routing domains, trusted and untrusted. All traffic within the environment have the ability to route to the trusted domain attachments and back, but traffic between those networks located in the untrusted domain is forbidden.
- Egress VPC: using either one of the above, this module can setup the requirements for an egress VPC to route traffic to the internet.
- Ingress VPC: using either one of the above, this module can setup the requirements for an ingress VPC to route traffic from the internet, to the tenant VPCs.

## Usage

Add ex}ample usage here

```hcl
module "example" {
  source  = "appvia/<NAME>/aws"
  version = "0.0.1"

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
      inspection_tgw_attachment_id = "tgw-attach-111111"
    }
  }

  providers = {
    aws         = aws
    aws.egress  = aws.egress
    aws.ingress = aws.ingress
  }
}
```

## Support Layouts

Currently the module supports the following layouts:

### Inspection Layout

<p align="center">
  <img src="docs/inspection.drawio.svg" alt="Inspection Layout" width="600"/>
<img erc

The inspection layout is intended to be used in collaboration with an [Inspection VPC](https://d1.awsstatic.com/architecture-diagrams/ArchitectureDiagrams/inspection-deployment-models-with-AWS-network-firewall-ra.pdf), filtering all traffic between the spokes, and depending if enabled, all traffic outbound to the internet or inbound via an ingress VPC.

```hcl
module "inspection" {
  source = "appvia/network/aws//modules/tgw_inspection"

  # insert variables here
  connectivity_config = {
    inspection = {
      # The transit gateway attachment (naturally a chicken and egg problem here, so the attachment is optional)
      attachment_id            = module.firewall.attachment_id
      # OR you can provision the vpc for the inspection vpc module to consume
      network = {
        availability_zones     = 2
        vpc_cidr               = "100.64.0.0/23"
        name                   = "inspection"
        private_subnet_netmask = 24
        public_subnet_netmask  = 24
      }
    }
  }
}
```

By adding the optional of egress, another VPC can be provisioned containing outbound nat gateways to route traffic to the internet.

```hcl
module "inspection" {
  source = "appvia/network/aws//modules/tgw_inspection"

  # insert variables here
  connectivity_config = {
    inspection = {
      network = {
        availability_zones     = 2
        vpc_cidr               = "100.64.0.0/23"
        name                   = "inspection"
        private_subnet_netmask = 24
        public_subnet_netmask  = 24
      }
    }
    egress = {
      network = {
        availability_zones = 2
        ipam_pool_id       = module.ipam_pool.id
        name               = "egress"
        vpc_netmask        = 24
      }
    }
  }
}
```

Notes:

- The transit gateway must be configured so that the default association table is the `inbound` routing table; alls spokes are immediately connected to the inspection VPC.
- The transit gateway must be configured so that the default propagation table is the `spokes` routing table; all traffic returning from the inspection VPC is routed to the correct spoke.
- If egress is enabled, a default route is added to the `return` routing table to route traffic to the egress VPC.
- If ingress is enabled, the spokes acts like any other spoke with all traffic being routed to the inspection VPC.

### Trusted Layout

<p align="center">
  <img src="docs/trusted.drawio.svg" alt="Trusted Layout" width="600"/>
</p>

The trusted layout uses transit gateway routing tables to create two distinct routing domains:

- Trusted: can see all networks and can route traffic to and from them.
- Untrusted: can only see the trusted networks, and **cannot** route traffic to or from any other untrusted network.

The most common usage pattern here is to place resources such as CI, monitoring, logging, remote access within the trusted domain, with all other accounts falling into untrusted. Any other connectivity requirements between the accounts must use alternative methods to communicate; for example [AWS Private Links](https://aws.amazon.com/privatelink/)

Notes:

- The transit gateway must be configured so that the default association table is default routing table, hence all new attachments are placed in the untrusted routing table.
- The transit gateway must be configured so that the default propagation table is the `trusted` routing table, this ensures that all traffic has a route from trusted to untrusted.
- Adding a new trusted requires manual intervention, i.e the network is automatically added to the untrusted routing table, manually deleted, and then the attachment id added to the trusted attachments variable.
- Any trusted attachments are automatically added to the untrusted routing table, to ensure bi-directional routing.

## Update Documentation

The `terraform-docs` utility is used to generate this README. Follow the below steps to update:

1. Make changes to the `.terraform-docs.yml` file
2. Fetch the `terraform-docs` binary (https://terraform-docs.io/user-guide/installation/)
3. Run `terraform-docs markdown table --output-file ${PWD}/README.md --output-mode inject .`

<!-- BEGIN_TF_DOCS -->

## Requirements

| Name                                                                     | Version  |
| ------------------------------------------------------------------------ | -------- |
| <a name="requirement_terraform"></a> [terraform](#requirement_terraform) | >= 1.0.7 |
| <a name="requirement_aws"></a> [aws](#requirement_aws)                   | >= 5.0.0 |

## Providers

| Name                                             | Version  |
| ------------------------------------------------ | -------- |
| <a name="provider_aws"></a> [aws](#provider_aws) | >= 5.0.0 |

## Modules

| Name                                                                          | Source                                    | Version |
| ----------------------------------------------------------------------------- | ----------------------------------------- | ------- |
| <a name="module_egress_vpc"></a> [egress_vpc](#module_egress_vpc)             | appvia/network/aws                        | 0.1.3   |
| <a name="module_ingress_vpc"></a> [ingress_vpc](#module_ingress_vpc)          | appvia/network/aws                        | 0.1.3   |
| <a name="module_inspection"></a> [inspection](#module_inspection)             | ./modules/tgw_inspection                  | n/a     |
| <a name="module_share_prefixes"></a> [share_prefixes](#module_share_prefixes) | ./modules/prefix_share                    | n/a     |
| <a name="module_tgw"></a> [tgw](#module_tgw)                                  | terraform-aws-modules/transit-gateway/aws | 2.12.2  |
| <a name="module_trusted"></a> [trusted](#module_trusted)                      | ./modules/tgw_trusted                     | n/a     |

## Resources

| Name                                                                                                                                                       | Type     |
| ---------------------------------------------------------------------------------------------------------------------------------------------------------- | -------- |
| [aws_ec2_managed_prefix_list.prefixes](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_managed_prefix_list)                | resource |
| [aws_ec2_transit_gateway_route.inspection_egress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_transit_gateway_route)   | resource |
| [aws_ec2_transit_gateway_route.trusted_default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_transit_gateway_route)     | resource |
| [aws_ec2_transit_gateway_route.trusted_route_table](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_transit_gateway_route) | resource |
| [aws_ram_principal_association.associations](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ram_principal_association)        | resource |
| [aws_ram_resource_association.prefixes](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ram_resource_association)              | resource |
| [aws_ram_resource_share.prefixes](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ram_resource_share)                          | resource |

## Inputs

| Name                                                                                                            | Description                                                                         | Type                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    | Default               | Required |
| --------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------- | :------: |
| <a name="input_amazon_side_asn"></a> [amazon_side_asn](#input_amazon_side_asn)                                  | The ASN for the transit gateway.                                                    | `number`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                | n/a                   |   yes    |
| <a name="input_connectivity_config"></a> [connectivity_config](#input_connectivity_config)                      | The type of connectivity options for the transit gateway.                           | <pre>object({<br> egress = optional(object({<br> attachment_id = optional(string, "")<br> network = optional(object({<br> availability_zones = number<br> ipam_pool_id = optional(string, null)<br> name = optional(string, "egress")<br> vpc_cidr = optional(string, null)<br> vpc_netmask = optional(string, null)<br> }), null)<br> }), null)<br> ingress = optional(object({<br> attachment_id = optional(string, "")<br> network = optional(object({<br> availability_zones = number<br> ipam_pool_id = optional(string, null)<br> name = optional(string, "ingress")<br> private_netmask = optional(number, null)<br> public_netmask = optional(number, null)<br> vpc_cidr = optional(string, null)<br> vpc_netmask = optional(string, null)<br> }), null)<br> }), null)<br> inspection = optional(object({<br> attachment_id = optional(string, "")<br> inbound_route_table_name = optional(string, "inbound")<br> spokes_route_table_name = optional(string, "spokes")<br> }), null)<br> trusted = optional(object({<br> trusted_attachments = optional(list(string), [])<br> trusted_route_table_name = optional(string, "trusted")<br> }), null)<br> })</pre> | n/a                   |   yes    |
| <a name="input_description"></a> [description](#input_description)                                              | The description of the transit gateway to provision.                                | `string`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                | n/a                   |   yes    |
| <a name="input_tags"></a> [tags](#input_tags)                                                                   | A map of tags to add to all resources.                                              | `map(string)`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           | n/a                   |   yes    |
| <a name="input_enable_dns_support"></a> [enable_dns_support](#input_enable_dns_support)                         | Whether DNS support is enabled.                                                     | `bool`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  | `true`                |    no    |
| <a name="input_enable_external_principals"></a> [enable_external_principals](#input_enable_external_principals) | Whether to enable external principals in the RAM share.                             | `bool`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  | `true`                |    no    |
| <a name="input_enable_multicast_support"></a> [enable_multicast_support](#input_enable_multicast_support)       | Whether multicast support is enabled.                                               | `bool`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  | `false`               |    no    |
| <a name="input_enable_vpn_ecmp_support"></a> [enable_vpn_ecmp_support](#input_enable_vpn_ecmp_support)          | Whether VPN Equal Cost Multipath Protocol support is enabled.                       | `bool`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  | `false`               |    no    |
| <a name="input_name"></a> [name](#input_name)                                                                   | The name of the transit gateway to provision.                                       | `string`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                | `"tgw-hub"`           |    no    |
| <a name="input_prefix_lists"></a> [prefix_lists](#input_prefix_lists)                                           | Provides the ability to provision prefix lists, and share them with other accounts. | <pre>list(object({<br> name = string<br> entry = list(object({<br> address_family = optional(string, "IPv4")<br> cidr = string<br> description = string<br> max_entries = number<br> }))<br> }))</pre>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  | `[]`                  |    no    |
| <a name="input_prefix_ram_principals"></a> [prefix_ram_principals](#input_prefix_ram_principals)                | The list of organizational units or accounts to share the prefix lists with.        | `list(string)`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          | `[]`                  |    no    |
| <a name="input_ram_share_name"></a> [ram_share_name](#input_ram_share_name)                                     | The name of the RAM share to create for the transit gateway.                        | `string`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                | `"tgw-hub-ram-share"` |    no    |
| <a name="input_ram_share_principals"></a> [ram_share_principals](#input_ram_share_principals)                   | The list of organizational units or accounts to share the transit gateway with.     | `list(string)`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          | `[]`                  |    no    |

## Outputs

| Name                                                                                      | Description                                         |
| ----------------------------------------------------------------------------------------- | --------------------------------------------------- |
| <a name="output_connectivity_type"></a> [connectivity_type](#output_connectivity_type)    | The type of connectivity for the transit gateway.   |
| <a name="output_egress_vpc_id"></a> [egress_vpc_id](#output_egress_vpc_id)                | The ID of the VPC that is used for egress traffic.  |
| <a name="output_ingress_vpc_id"></a> [ingress_vpc_id](#output_ingress_vpc_id)             | The ID of the VPC that is used for ingress traffic. |
| <a name="output_transit_gateway_id"></a> [transit_gateway_id](#output_transit_gateway_id) | The ID of the transit gateway.                      |

<!-- END_TF_DOCS -->

```

```

```

```
