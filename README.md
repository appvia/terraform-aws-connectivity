<!-- markdownlint-disable -->

<a href="https://www.appvia.io/"><img src="https://github.com/appvia/terraform-aws-connectivity/blob/main/appvia_banner.jpg?raw=true" alt="Appvia Banner"/></a><br/><p align="right"> <a href="https://registry.terraform.io/modules/appvia/connectivity/aws/latest"><img src="https://img.shields.io/static/v1?label=APPVIA&message=Terraform%20Registry&color=191970&style=for-the-badge" alt="Terraform Registry"/></a></a> <a href="https://github.com/appvia/terraform-aws-connectivity/releases/latest"><img src="https://img.shields.io/github/release/appvia/terraform-aws-connectivity.svg?style=for-the-badge&color=006400" alt="Latest Release"/></a> <a href="https://appvia-community.slack.com/join/shared_invite/zt-1s7i7xy85-T155drryqU56emm09ojMVA#/shared-invite/email"><img src="https://img.shields.io/badge/Slack-Join%20Community-purple?style=for-the-badge&logo=slack" alt="Slack Community"/></a> <a href="https://github.com/appvia/terraform-aws-connectivity/graphs/contributors"><img src="https://img.shields.io/github/contributors/appvia/terraform-aws-connectivity.svg?style=for-the-badge&color=FF8C00" alt="Contributors"/></a>

<!-- markdownlint-restore -->
<!--
  ***** CAUTION: DO NOT EDIT ABOVE THIS LINE ******
-->

![Github Actions](https://github.com/appvia/terraform-aws-connectivity/actions/workflows/terraform.yml/badge.svg)

# Terraform AWS Connectivity Module

## Description

The purpose of this module is to provision the necessary resources to establish connectivity between a transit gateway and other VPCs, accounts, and on-premises networks, as well as provision a baseline for network topology and security. Currently this module can setup the requirement for

- Inspection VPC: provision the necessary resources and routing to inspect traffic between the transit gateway and spoke VPCs.
- Trusted Layout: here the routing is broken into two routing domains, trusted and untrusted. All traffic within the environment have the ability to route to the trusted domain attachments and back, but traffic between those networks located in the untrusted domain is forbidden.
- Egress VPC: using either one of the above, this module can setup the requirements for an egress VPC to route traffic to the internet.
- Ingress VPC: using either one of the above, this module can setup the requirements for an ingress VPC to route traffic from the internet, to the tenant VPCs.

## Usage

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
}
```

## Support Layouts

Currently the module supports the following layouts:

### Inspection Layout

<p align="center">
  </br>
  <img src="https://github.com/appvia/terraform-aws-connectivity/blob/main/docs/inspection.drawio.svg?raw=true" alt="Inspection Layout" width="600"/>
</p>

The inspection layout is intended to be used in collaboration with an [Inspection VPC](https://d1.awsstatic.com/architecture-diagrams/ArchitectureDiagrams/inspection-deployment-models-with-AWS-network-firewall-ra.pdf), filtering all traffic between the spokes, and depending if enabled, all traffic outbound to the internet or inbound via an ingress VPC.

```hcl
module "connectivity" {
  source  = "appvia/connectivity/aws"
  version = "0.1.7""

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

Note we do not deploy the inspection firewall via this repository; purely the networking, layout, routing required to make it happen. This is intentional as we view the firewall configuration is likely to fall under a different teams remit. This can be configured using the [terraform-aws-firewall](https://github.com/appvia/terraform-aws-firewall).

By adding the optional of egress, another VPC can be provisioned containing outbound nat gateways to route traffic to the internet.

```hcl
module "connectivity" {
  source  = "appvia/connectivity/aws"
  version = "0.0.2"

  services = {
    egress = {
      network = {
        availability_zones = 2
        ipam_pool_id       = module.ipam_pool.id
        name               = "egress"
        vpc_netmask        = 24
      }
    }
  }

  # insert variables here
  connectivity_config = {
    inspection = {
      network = {
        availability_zones = 2
        vpc_cidr           = "100.64.0.0/21"
        name               = "inspection"
        private_netmask    = 24
        public_netmask     = 24
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
  </br>
  <img src="https://github.com/appvia/terraform-aws-connectivity/blob/main/docs/trusted.drawio.svg?raw=true" alt="Trusted Layout" width="600"/>
</p>

The trusted layout uses transit gateway routing tables to create two distinct routing domains:

- Trusted: can see all networks and can route traffic to and from them.
- Untrusted: can only see the trusted networks, and **cannot** route traffic to or from any other untrusted network.

The most common usage pattern here is to place resources such as CI, monitoring, logging, remote access within the trusted domain, with all other accounts falling into untrusted. Any other connectivity requirements between the accounts must use alternative methods to communicate; for example [AWS Private Links](https://aws.amazon.com/privatelink/)

Notes:

- The transit gateway must be configured so that the default association table is `workloads` routing table, hence all new attachments are placed in the untrusted routing table.
- The transit gateway must be configured so that the default propagation table is the `trusted` routing table, this ensures that all traffic has a route from trusted to untrusted.
- Adding a new trusted requires manual intervention, i.e the network is automatically added to the untrusted routing table, manually deleted, and then the attachment id added to the trusted attachments variable.
- Any trusted attachments are automatically added to the untrusted routing table, to ensure bi-directional routing.

### Egress VPC

<p align="center">
  </br>
  <img src="https://github.com/appvia/terraform-aws-connectivity/blob/main/docs/egress-vpc.png?raw=true" alt="Egress VPC">
</p>

By adding a `var.connectivity_config.egress` object, the module will provision the necessary resources to route traffic to the internet via a shared egress VPC. Routing within the choose network layout (inspection, or trusted) is automatically provisioned accordingly.

```hcl
module "connectivity" {
  source  = "appvia/connectivity/aws"
  version = "0.0.2"

  connectivity_config = {
    egress = {
      network = {
        availability_zones = 2
        ipam_pool_id       = var.ipam_pool_id
        name               = "egress"
        private_netmask    = 28
        vpc_netmask        = 24
      }
    }
  }
}
```

### Ingress VPC

<p align="center">
  </br>
  <img src="https://github.com/appvia/terraform-aws-connectivity/blob/main/docs/ingress-vpc.png?raw=true" alt="Ingress VPC">
</p>

By adding a `var.connectivity_config.ingress` object, the module will provision the necessary resources to route traffic from the internet to the tenant VPCs. Routing within the choose network layout (inspection, or trusted) is automatically provisioned accordingly. Note, this module does not provisioned the load balancers and or WAF devices depicted in the diagram; purely the VPC and connectivity.

```hcl
module "connectivity" {
  source  = "appvia/connectivity/aws"
  version = "0.0.2"

  connectivity_config = {
    ingress = {
      network = {
        availability_zones = 2
        ipam_pool_id       = var.ipam_pool_id
        name               = "ingress"
        private_netmask    = 24
        public_netmask     = 22
        vpc_netmask        = 21
      }
    }
  }
}
```

### Private Endpoints

Ensuring all traffic is private and does not traverse the internet is a common requirement. By adding the `var.connectivity_config.endpoints` object, the module will provision the necessary resources to route traffic to the internet via a shared endpoints VPC. Routing within the choose network layout (inspection, or trusted) is automatically provisioned accordingly.

Take a look at the [endpoints module](https://github.com/appvia/terraform-aws-private-endpoints) to see how it works, and the prerequisites required on the consumer side i.e associating the resolvers rule sets with the spoke vpc.

```hcl
module "connectivity" {
  source  = "appvia/connectivity/aws"
  version = "0.0.2"

  connectivity_config = {
    endpoints = {
      # A collection of private endpoints to provision
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
        logs = {
          service = "logs"
        },
        kms = {
          service = "kms"
        },
        secretsmanager = {
          service = "secretsmanager"
        },
        s3 = {
          service = "s3"
        },
      }
      # Configuration for sharing the resolver rule sets with the spoke vpcs
      sharing = {
        ram_principals = var.ram_principals
      }
      # Configuration for the endpoints vpc
      network = {
        availability_zones = 2
        ipam_pool_id       = var.ipam_pool_id
        name               = "endpoints"
        private_netmask    = 24
        public_netmask     = 22
        vpc_netmask        = 21
      }
    }

  }
}
```

## IAM Roles (Cloud Access)

The following permissions are required by the module

```hcl
module "network_transit_gateway_admin" {
  count   = var.repositories.connectivity != null ? 1 : 0
  source  = "appvia/oidc/aws//modules/role"
  version = "1.3.6"

  name                    = var.repositories.connectivity.role_name
  description             = "Deployment role used to deploy the Transit Gateway"
  permission_boundary_arn = aws_iam_policy.default_permissions_boundary_network[0].arn
  repository              = var.repositories.connectivity.url
  tags                    = var.tags

  read_only_policy_arns = [
    "arn:aws:iam::aws:policy/AWSResourceAccessManagerReadOnlyAccess",
    "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess",
    "arn:aws:iam::aws:policy/ReadOnlyAccess",
  ]
  read_write_policy_arns = [
    "arn:aws:iam::${local.network_account_id}:policy/${aws_iam_policy.ipam_admin[0].name}",
    "arn:aws:iam::aws:policy/AWSResourceAccessManagerFullAccess",
    "arn:aws:iam::aws:policy/ReadOnlyAccess",
    "arn:aws:iam::aws:policy/job-function/NetworkAdministrator",
    "arn:aws:iam::aws:policy/AmazonEC2FullAccess",
  ]

  read_write_inline_policies = {
    "endpoints" = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action = [
            "route53resolver:Associate*",
            "route53resolver:Create*",
            "route53resolver:Delete*",
            "route53resolver:Disassociate*",
            "route53resolver:Get*",
            "route53resolver:List*",
            "route53resolver:Tag*",
            "route53resolver:Update*",
            "Route53resolver:UnTag*"
          ]
          Effect   = "Allow"
          Resource = "*"
        }
      ]
    })
  }

 # We can share our state with the firewall module
 shared_repositories = var.repositories.firewall != null ? [var.repositories.firewall.url] : []

 providers = {
   aws = aws.network
 }
}
```

## Update Documentation

The `terraform-docs` utility is used to generate this README. Follow the below steps to update:

1. Make changes to the `.terraform-docs.yml` file
2. Fetch the `terraform-docs` binary (https://terraform-docs.io/user-guide/installation/)
3. Run `terraform-docs markdown table --output-file ${PWD}/README.md --output-mode inject .`

<!-- BEGIN_TF_DOCS -->
## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 5.0.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_amazon_side_asn"></a> [amazon\_side\_asn](#input\_amazon\_side\_asn) | The ASN for the transit gateway. | `number` | n/a | yes |
| <a name="input_connectivity_config"></a> [connectivity\_config](#input\_connectivity\_config) | The type of connectivity options for the transit gateway. | <pre>object({<br/>    inspection_with_all = optional(object({<br/>      # The name of the inbound route table. Defaults to 'inbound'. <br/>      network = optional(object({<br/>        # Defines the configuration for the inspection network. <br/>        availability_zones = number<br/>        # The number of availablity zones to use for the inspection network. Required. Must match the <br/>        # number of availability zones you use in the organization, due to symmetric routing requirements. <br/>        name = optional(string, "inspection")<br/>        # The name of the inspection network. Defaults to 'inspection'. <br/>        private_netmask = optional(number, 24)<br/>        # The netmask to use for the private network. Defaults to 24<br/>        vpc_cidr = optional(string, "100.64.0.0/21")<br/>        # The CIDR block to use for the VPC. Defaults to carrier-grade NAT space. <br/>      }), null)<br/>      return_route_table_name = optional(string, "inspection-return")<br/>    }), null)<br/><br/>    trusted = optional(object({<br/>      # Defines the configuration for the trusted routing<br/>      trusted_attachments = optional(map(string), {})<br/>      # The list of transit gateway attachments to trust e.g can see all the other untrusted networks. Defaults to an empty list.<br/>      trusted_route_table_name = optional(string, "trusted")<br/>      # The name of the trusted route table. Defaults to 'trusted'.<br/>      trusted_core_route_table_name = optional(string, "trusted-core")<br/>    }), null)<br/>  })</pre> | n/a | yes |
| <a name="input_description"></a> [description](#input\_description) | The description of the transit gateway to provision. | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to add to all resources. | `map(string)` | n/a | yes |
| <a name="input_enable_dns_support"></a> [enable\_dns\_support](#input\_enable\_dns\_support) | Whether DNS support is enabled. | `bool` | `true` | no |
| <a name="input_enable_external_principals"></a> [enable\_external\_principals](#input\_enable\_external\_principals) | Whether to enable external principals in the RAM share. | `bool` | `true` | no |
| <a name="input_enable_multicast_support"></a> [enable\_multicast\_support](#input\_enable\_multicast\_support) | Whether multicast support is enabled. | `bool` | `false` | no |
| <a name="input_enable_vpn_ecmp_support"></a> [enable\_vpn\_ecmp\_support](#input\_enable\_vpn\_ecmp\_support) | Whether VPN Equal Cost Multipath Protocol support is enabled. | `bool` | `false` | no |
| <a name="input_name"></a> [name](#input\_name) | The name of the transit gateway to provision. | `string` | `"tgw"` | no |
| <a name="input_prefix_lists"></a> [prefix\_lists](#input\_prefix\_lists) | Provides the ability to provision prefix lists, and share them with other accounts. | <pre>list(object({<br/>    name = string<br/>    entry = list(object({<br/>      address_family = optional(string, "IPv4")<br/>      cidr           = string<br/>      description    = string<br/>      max_entries    = number<br/>    }))<br/>  }))</pre> | `[]` | no |
| <a name="input_prefix_ram_principals"></a> [prefix\_ram\_principals](#input\_prefix\_ram\_principals) | The list of organizational units or accounts to share the prefix lists with. | `list(string)` | `[]` | no |
| <a name="input_ram_share_name"></a> [ram\_share\_name](#input\_ram\_share\_name) | The name of the RAM share to create for the transit gateway. | `string` | `"tgw-ram-share"` | no |
| <a name="input_ram_share_principals"></a> [ram\_share\_principals](#input\_ram\_share\_principals) | The list of organizational units or accounts to share the transit gateway with. | `list(string)` | `[]` | no |
| <a name="input_services"></a> [services](#input\_services) | A collection of features and services associated with this connectivity domain. | <pre>object({<br/>    egress = optional(object({<br/>      network = object({<br/>        # Defines the configuration for an egress network. <br/>        availability_zones = optional(number, 2)<br/>        # The number of availablity zones to use for the egress network. Defaults to 2.<br/>        ipam_pool_id = optional(string, null)<br/>        # The ID of the IPAM pool to use for the egress network. Defaults to null. <br/>        name = optional(string, "egress")<br/>        # The name of the egress network. Defaults to 'egress'. <br/>        private_netmask = optional(number, 28)<br/>        # The netmask to use for the private network. Defaults to 28. <br/>        public_netmask = optional(number, 28)<br/>        # The netmask to use for the public network. Defaults to 28. <br/>        transit_gateway_routes = optional(map(string), {<br/>          private = "10.0.0.0/8"<br/>          public  = "10.0.0.0/8"<br/>        })<br/>        # The transit gateway route tables entries for the egress network.<br/>        vpc_cidr = optional(string, null)<br/>        # The CIDR block to use for the VPC. Defaults to null, required when not using IPAM<br/>        vpc_netmask = optional(string, null)<br/>        # The netmask to use for the VPC. Defaults to null, required when using IPAM<br/>      })<br/>    }), null)<br/>    dns = optional(object({<br/>      # The list of organizational units or accounts to share the domain rule with. <br/>      resolver_name = optional(string, "dns-resolver")<br/><br/>      # Defines the configuration for the endpoints network. <br/>      network = object({<br/>        # Defines the configuration for the endpoints network. <br/>        availability_zones = optional(number, 2)<br/>        # The number of availablity zones to use for the endpoints network. Defaults to 2. <br/>        ipam_pool_id = optional(string, null)<br/>        # The ID of the IPAM pool to use for the endpoints network. Defaults to null. <br/>        name = optional(string, "central-dns")<br/>        # The name of the endpoints network. Defaults to 'endpoints'. <br/>        private_netmask = optional(number, 24)<br/>        # The netmask to use for the private network. Defaults to 24, ensure space for enough aws services. <br/>        vpc_cidr = optional(string, null)<br/>        # The CIDR block to use for the VPC. Defaults to null, required when not using IPAM <br/>        vpc_netmask = optional(string, null)<br/>        # The netmask to use for the VPC. Defaults to null, required when using IPAM <br/>      }),<br/><br/>      domain_rules = optional(list(object({<br/>        ram_share_name = optional(string, "central-dns")<br/>        # The name of the domain rule - this is mapped to the resource share name <br/>        ram_principals = optional(map(string), {})<br/>        # The name of the resolver to use. Defaults to 'dns-resolver'.<br/>        rules = list(object({<br/>          name = string<br/>          # The name of the rule - the ram share name is domain.name + "-" + rule.name <br/>          # The list of domain rules to apply to the domain. <br/>          domain = string<br/>          # The domain to apply the rule to. <br/>          targets = optional(list(string), [])<br/>          # The list of targets to apply the rule to - defaults to local resolver.<br/>        }))<br/>      })), [])<br/>    }), null)<br/><br/>    endpoints = optional(object({<br/>      # Defines the configuration for the endpoints network. <br/>      network = object({<br/>        # Defines the configuration for the endpoints network. <br/>        availability_zones = optional(number, 2)<br/>        # The number of availablity zones to use for the endpoints network. Defaults to 2. <br/>        ipam_pool_id = optional(string, null)<br/>        # The ID of the IPAM pool to use for the endpoints network. Defaults to null. <br/>        name = optional(string, "endpoints")<br/>        # The name of the endpoints network. Defaults to 'endpoints'. <br/>        private_netmask = optional(number, 24)<br/>        # The netmask to use for the private network. Defaults to 24, ensure space for enough aws services. <br/>        vpc_cidr = optional(string, null)<br/>        # The CIDR block to use for the VPC. Defaults to null, required when not using IPAM <br/>        vpc_netmask = optional(string, null)<br/>        # The netmask to use for the VPC. Defaults to null, required when using IPAM <br/>      })<br/>      sharing = optional(object({<br/>        # Defines the configuration for the sharing network via AWS RAM <br/>        principals = optional(list(string), [])<br/>        # The list of organizational units or accounts to share the endpoints resolvers rules with. Defaults to an empty list.<br/>      }), null)<br/>      services = optional(map(object({<br/>        # Defines the configuration for the private endpoints in the shared network. <br/>        private_dns_enabled = optional(bool, true)<br/>        # Whether private DNS is enabled. Defaults to true. <br/>        service_type = optional(string, "Interface")<br/>        # The type of service, i.e. Gateway or Interface. Defaults to 'Interface'<br/>        service = string<br/>        # The name of the service i.e. ec2, ec2messages, ssm, ssmmessages, logs, kms, secretsmanager, s3.awsamazon.com<br/>        policy = optional(string, null)<br/>        # An optional IAM policy to use for the endpoint. Defaults to null.<br/>        })), {<br/>        ec2messages = {<br/>          service = "ec2messages"<br/>        },<br/>        ssm = {<br/>          service = "ssm"<br/>        },<br/>        ssmmessages = {<br/>          service = "ssmmessages"<br/>        },<br/>      })<br/>    }), null)<br/>    ingress = optional(object({<br/>      # Defines the configuration for the ingress network. <br/>      network = object({<br/>        # Defines the configuration for the ingress network. <br/>        availability_zones = optional(number, 2)<br/>        # The number of availablity zones to use for the ingress network. Defaults to 2. <br/>        ipam_pool_id = optional(string, null)<br/>        # The ID of the IPAM pool to use for the ingress network. Defaults to null. <br/>        name = optional(string, "ingress")<br/>        # The name of the ingress network. Defaults to 'ingress'. <br/>        private_netmask = number<br/>        # The netmask to use for the private network. Required, ensure space for enough aws services. <br/>        public_netmask = number<br/>        # The netmask to use for the public network. Required, ensure space for enough aws services. <br/>        vpc_cidr = optional(string, null)<br/>        # The CIDR block to use for the VPC. Defaults to null, required when not using IPAM <br/>        vpc_netmask = optional(string, null)<br/>        # The netmask to use for the VPC. Defaults to null, required when using IPAM <br/>      })<br/>    }), null)<br/>  })</pre> | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_account_id"></a> [account\_id](#output\_account\_id) | The AWS account ID. |
| <a name="output_connectivity_type"></a> [connectivity\_type](#output\_connectivity\_type) | The type of connectivity for the transit gateway. |
| <a name="output_egress_vpc_id"></a> [egress\_vpc\_id](#output\_egress\_vpc\_id) | The ID of the VPC that is used for egress traffic. |
| <a name="output_egress_vpc_id_rt_attributes_by_type_by_az"></a> [egress\_vpc\_id\_rt\_attributes\_by\_type\_by\_az](#output\_egress\_vpc\_id\_rt\_attributes\_by\_type\_by\_az) | The route table attributes of the egress VPC. |
| <a name="output_egress_vpc_private_subnet_attributes_by_az"></a> [egress\_vpc\_private\_subnet\_attributes\_by\_az](#output\_egress\_vpc\_private\_subnet\_attributes\_by\_az) | The attributes of the egress VPC. |
| <a name="output_egress_vpc_public_subnet_attributes_by_az"></a> [egress\_vpc\_public\_subnet\_attributes\_by\_az](#output\_egress\_vpc\_public\_subnet\_attributes\_by\_az) | The attributes of the egress VPC. |
| <a name="output_endpoints_vpc_id"></a> [endpoints\_vpc\_id](#output\_endpoints\_vpc\_id) | The ID of the VPC that is used for endpoint traffic. |
| <a name="output_endpoints_vpc_id_rt_attributes_by_type_by_az"></a> [endpoints\_vpc\_id\_rt\_attributes\_by\_type\_by\_az](#output\_endpoints\_vpc\_id\_rt\_attributes\_by\_type\_by\_az) | The route table attributes of the endpoints VPC. |
| <a name="output_endpoints_vpc_private_subnet_attributes_by_az"></a> [endpoints\_vpc\_private\_subnet\_attributes\_by\_az](#output\_endpoints\_vpc\_private\_subnet\_attributes\_by\_az) | The attributes of the endpoints VPC. |
| <a name="output_ingress_vpc_id"></a> [ingress\_vpc\_id](#output\_ingress\_vpc\_id) | The ID of the VPC that is used for ingress traffic. |
| <a name="output_ingress_vpc_id_rt_attributes_by_type_by_az"></a> [ingress\_vpc\_id\_rt\_attributes\_by\_type\_by\_az](#output\_ingress\_vpc\_id\_rt\_attributes\_by\_type\_by\_az) | The route table attributes of the ingress VPC. |
| <a name="output_ingress_vpc_private_subnet_attributes_by_az"></a> [ingress\_vpc\_private\_subnet\_attributes\_by\_az](#output\_ingress\_vpc\_private\_subnet\_attributes\_by\_az) | The attributes of the ingress VPC. |
| <a name="output_ingress_vpc_public_subnet_attributes_by_az"></a> [ingress\_vpc\_public\_subnet\_attributes\_by\_az](#output\_ingress\_vpc\_public\_subnet\_attributes\_by\_az) | The attributes of the ingress VPC. |
| <a name="output_inspection_route_inbound_table_id"></a> [inspection\_route\_inbound\_table\_id](#output\_inspection\_route\_inbound\_table\_id) | The ID of the inbound route table for inspection. |
| <a name="output_inspection_vpc_id"></a> [inspection\_vpc\_id](#output\_inspection\_vpc\_id) | The ID of the VPC that is used for inspection traffic. |
| <a name="output_inspection_vpc_id_rt_attributes_by_type_by_az"></a> [inspection\_vpc\_id\_rt\_attributes\_by\_type\_by\_az](#output\_inspection\_vpc\_id\_rt\_attributes\_by\_type\_by\_az) | The route table attributes of the inspection VPC. |
| <a name="output_inspection_vpc_private_subnet_attributes_by_az"></a> [inspection\_vpc\_private\_subnet\_attributes\_by\_az](#output\_inspection\_vpc\_private\_subnet\_attributes\_by\_az) | The attributes of the inspection VPC. |
| <a name="output_inspection_vpc_public_subnet_attributes_by_az"></a> [inspection\_vpc\_public\_subnet\_attributes\_by\_az](#output\_inspection\_vpc\_public\_subnet\_attributes\_by\_az) | The attributes of the inspection VPC. |
| <a name="output_region"></a> [region](#output\_region) | The AWS region in which the resources are created. |
| <a name="output_transit_gateway_id"></a> [transit\_gateway\_id](#output\_transit\_gateway\_id) | The ID of the transit gateway. |
| <a name="output_trusted_core_route_table_id"></a> [trusted\_core\_route\_table\_id](#output\_trusted\_core\_route\_table\_id) | The ID of the trusted core route table. |
| <a name="output_trusted_route_table_id"></a> [trusted\_route\_table\_id](#output\_trusted\_route\_table\_id) | The ID of the trusted route table. |
| <a name="output_workloads_route_table_id"></a> [workloads\_route\_table\_id](#output\_workloads\_route\_table\_id) | The ID of the workloads route table. |
<!-- END_TF_DOCS -->

```

```
