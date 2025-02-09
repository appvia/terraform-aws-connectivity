<!-- markdownlint-disable -->

<a href="https://www.appvia.io/"><img src="https://github.com/appvia/terraform-aws-connectivity/blob/main/docs/banner.jpg?raw=true" alt="Appvia Banner"/></a><br/><p align="right"> <a href="https://registry.terraform.io/modules/appvia/connectivity/aws/latest"><img src="https://img.shields.io/static/v1?label=APPVIA&message=Terraform%20Registry&color=191970&style=for-the-badge" alt="Terraform Registry"/></a></a> <a href="https://github.com/appvia/terraform-aws-connectivity/releases/latest"><img src="https://img.shields.io/github/release/appvia/terraform-aws-connectivity.svg?style=for-the-badge&color=006400" alt="Latest Release"/></a> <a href="https://appvia-community.slack.com/join/shared_invite/zt-1s7i7xy85-T155drryqU56emm09ojMVA#/shared-invite/email"><img src="https://img.shields.io/badge/Slack-Join%20Community-purple?style=for-the-badge&logo=slack" alt="Slack Community"/></a> <a href="https://github.com/appvia/terraform-aws-connectivity/graphs/contributors"><img src="https://img.shields.io/github/contributors/appvia/terraform-aws-connectivity.svg?style=for-the-badge&color=FF8C00" alt="Contributors"/></a>

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
  source  = "appvia/connectivity/aws//modules/inspection"
  version = "0.1.7""

  # insert variables here
  connectivity_config = {
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
```

Note we do not deploy the inspection firewall via this repository; purely the networking, layout, routing required to make it happen. This is intentional as we view the firewall configuration is likely to fall under a different teams remit. This can be configured using the [terraform-aws-firewall](https://github.com/appvia/terraform-aws-firewall).

By adding the optional of egress, another VPC can be provisioned containing outbound nat gateways to route traffic to the internet.

```hcl
module "connectivity" {
  source  = "appvia/connectivity/aws//modules/inspection"
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
    network = {
      availability_zones = 2
      vpc_cidr           = "100.64.0.0/21"
      name               = "inspection"
      private_netmask    = 24
      public_netmask     = 24
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
  source  = "appvia/connectivity/aws//modules/<LAYOUT>"
  version = "0.0.2"

  services = {
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
  ...
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

  services = {
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

  services = {
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

No providers.

## Inputs

No inputs.

## Outputs

No outputs.
<!-- END_TF_DOCS -->

```

```
