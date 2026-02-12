<!-- markdownlint-disable -->

<a href="https://www.appvia.io/"><img src="https://github.com/appvia/terraform-aws-connectivity/blob/main/docs/banner.jpg?raw=true" alt="Appvia Banner"/></a><br/><p align="right"> <a href="https://registry.terraform.io/modules/appvia/connectivity/aws/latest"><img src="https://img.shields.io/static/v1?label=APPVIA&message=Terraform%20Registry&color=191970&style=for-the-badge" alt="Terraform Registry"/></a></a> <a href="https://github.com/appvia/terraform-aws-connectivity/releases/latest"><img src="https://img.shields.io/github/release/appvia/terraform-aws-connectivity.svg?style=for-the-badge&color=006400" alt="Latest Release"/></a> <a href="https://appvia-community.slack.com/join/shared_invite/zt-1s7i7xy85-T155drryqU56emm09ojMVA#/shared-invite/email"><img src="https://img.shields.io/badge/Slack-Join%20Community-purple?style=for-the-badge&logo=slack" alt="Slack Community"/></a> <a href="https://github.com/appvia/terraform-aws-connectivity/graphs/contributors"><img src="https://img.shields.io/github/contributors/appvia/terraform-aws-connectivity.svg?style=for-the-badge&color=FF8C00" alt="Contributors"/></a>

<!-- markdownlint-restore -->
<!--
  ***** CAUTION: DO NOT EDIT ABOVE THIS LINE ******
-->

![Github Actions](https://github.com/appvia/terraform-aws-connectivity/actions/workflows/terraform.yml/badge.svg)

# Terraform AWS Connectivity Module

## Description

### Problem and Solution

Building secure, scalable network connectivity across multiple AWS accounts and VPCs is complex. Transit gateways require careful orchestration of route tables, associations, propagations, and optional inspection or segmentation. This module standardizes that connectivity by provisioning the necessary resources to establish Transit Gateway–based hub-and-spoke topologies with optional traffic inspection, trusted/untrusted segmentation, and shared egress/ingress/endpoints VPCs.

### Architecture Overview

The module provides two layout types—**Inspection** and **Trusted**—each deployed via its own submodule (`modules/inspection` or `modules/trusted`). Both create a Transit Gateway with configurable route tables. The Inspection layout centralizes traffic through an inspection VPC for filtering; the Trusted layout uses routing domains to isolate trusted workloads from untrusted ones. Optional services (egress, ingress, endpoints, DNS) can be added via the `services` object and are integrated into the chosen layout’s routing automatically.

### Cloud Context

Designed for multi-account AWS environments (e.g., landing zones, organizational units). Supports RAM sharing for cross-account transit gateway access and integrates with [terraform-aws-firewall](https://github.com/appvia/terraform-aws-firewall) for inspection deployment.

### Feature Set

- **Security by Default**: Route tables isolate traffic; inspection layout enforces traffic via inspection VPC; trusted layout enforces segmentation between untrusted spokes.
- **Flexibility**: Supports both Inspection and Trusted layouts; optional egress, ingress, endpoints, and central DNS via `services` object; IPAM or manual CIDR assignment.
- **Operational Excellence**: Transit Gateway route table naming and structure aligned with common patterns; integration with Appvia networking modules.
- **Compliance**: Suitable for architectures requiring traffic inspection, east-west segmentation, and centralized egress/ingress.

## Usage Gallery

### Golden Path (Simple)

Minimal inspection layout with inspection VPC only:

```hcl
module "connectivity" {
  source  = "appvia/connectivity/aws//modules/inspection"
  version = "0.1.7"

  name                       = "hub-tgw"
  description                = "Transit gateway for all accounts in this region"
  amazon_side_asn            = 64512
  enable_dns_support         = true
  enable_external_principals = true
  enable_multicast_support   = false
  enable_vpn_ecmp_support    = false
  tags                       = { Environment = "prod" }

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
```

### Power User (Advanced)

Inspection layout with egress, ingress, and endpoints services:

```hcl
module "connectivity" {
  source  = "appvia/connectivity/aws//modules/inspection"
  version = "0.1.7"

  name                       = "hub-tgw"
  description                = "Transit gateway for all accounts in this region"
  amazon_side_asn            = 64512
  enable_dns_support         = true
  enable_external_principals = true
  enable_multicast_support   = false
  enable_vpn_ecmp_support    = false
  tags                       = { Environment = "prod" }

  services = {
    egress = {
      network = {
        availability_zones = 2
        name               = "egress"
        vpc_cidr           = "10.20.0.0/21"
        private_netmask    = 24
        public_netmask     = 24
      }
    }
    ingress = {
      network = {
        availability_zones = 2
        name               = "ingress"
        vpc_cidr           = "10.20.8.0/21"
        private_netmask    = 24
        public_netmask     = 24
      }
    }
    endpoints = {
      network = {
        availability_zones = 2
        name               = "endpoints"
        vpc_cidr           = "10.20.16.0/21"
        private_netmask    = 24
      }
      sharing = {
        principals = ["arn:aws:organizations::123456789012:ou/ou-xxxx"]
      }
      services = {
        ec2messages = { service = "ec2messages" }
        ssm         = { service = "ssm" }
        ssmmessages = { service = "ssmmessages" }
      }
    }
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
```

### Migration (Edge Case)

Trusted layout with existing trusted attachments (requires manual association of new spokes to trusted route table):

```hcl
module "connectivity" {
  source  = "appvia/connectivity/aws//modules/trusted"
  version = "0.1.7"

  name                       = "hub-tgw"
  description                = "Transit gateway for all accounts in this region"
  amazon_side_asn            = 64512
  enable_dns_support         = true
  enable_external_principals = true
  tags                       = { Environment = "prod" }

  connectivity_config = {
    trusted_attachments = {
      "ci-monitoring" = "tgw-attach-xxxxxxxx"
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

The module provisions the inspection VPC network and routing; it does **not** deploy the inspection firewall. Firewall configuration is handled by [terraform-aws-firewall](https://github.com/appvia/terraform-aws-firewall).

Inspection layout example with optional egress:

```hcl
module "connectivity" {
  source  = "appvia/connectivity/aws//modules/inspection"
  version = "0.1.7"

  name                       = "hub-tgw"
  description                = "Transit gateway for all accounts in this region"
  amazon_side_asn            = 64512
  enable_dns_support         = true
  enable_external_principals = true
  tags                       = var.tags

  services = {
    egress = {
      network = {
        availability_zones = 2
        name               = "egress"
        vpc_cidr           = "10.20.0.0/21"
        private_netmask    = 24
        public_netmask     = 24
      }
    }
  }

  connectivity_config = {
    network = {
      availability_zones = 2
      vpc_cidr           = "100.64.0.0/21"
      name               = "inspection"
      private_netmask     = 24
      public_netmask      = 0
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

By adding a `services.egress` object, the module provisions the necessary resources to route traffic to the internet via a shared egress VPC. Routing within the chosen layout (inspection or trusted) is provisioned automatically.

```hcl
module "connectivity" {
  source  = "appvia/connectivity/aws//modules/inspection"
  version = "0.1.7"

  # ... name, description, amazon_side_asn, tags, connectivity_config ...

  services = {
    egress = {
      network = {
        availability_zones = 2
        name               = "egress"
        vpc_cidr           = "10.20.0.0/21"
        private_netmask    = 28
        public_netmask     = 28
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

By adding a `services.ingress` object, the module provisions the necessary resources to route traffic from the internet to the tenant VPCs. Routing within the chosen layout (inspection or trusted) is provisioned automatically. Note: this module does not provision load balancers or WAF devices; purely the VPC and connectivity.

```hcl
module "connectivity" {
  source  = "appvia/connectivity/aws//modules/inspection"
  version = "0.1.7"

  # ... name, description, amazon_side_asn, tags, connectivity_config ...

  services = {
    ingress = {
      network = {
        availability_zones = 2
        name               = "ingress"
        vpc_cidr           = "10.20.8.0/21"
        private_netmask    = 24
        public_netmask     = 22
      }
    }
  }
}
```

### Private Endpoints

Ensuring all traffic is private and does not traverse the internet is a common requirement. By adding a `services.endpoints` object, the module provisions the necessary resources for a shared endpoints VPC with private endpoints. Routing within the chosen layout (inspection or trusted) is provisioned automatically.

See the [terraform-aws-private-endpoints](https://github.com/appvia/terraform-aws-private-endpoints) module for details and consumer-side prerequisites (e.g., associating resolver rule sets with spoke VPCs).

```hcl
module "connectivity" {
  source  = "appvia/connectivity/aws//modules/inspection"
  version = "0.1.7"

  # ... name, description, amazon_side_asn, tags, connectivity_config ...

  services = {
    endpoints = {
      services = {
        ec2           = { service = "ec2" }
        ec2messages   = { service = "ec2messages" }
        ssm           = { service = "ssm" }
        ssmmessages   = { service = "ssmmessages" }
        logs          = { service = "logs" }
        kms           = { service = "kms" }
        secretsmanager = { service = "secretsmanager" }
        s3            = { service = "s3" }
      }
      sharing = {
        principals = ["arn:aws:organizations::123456789012:ou/ou-xxxx"]
      }
      network = {
        availability_zones = 2
        name               = "endpoints"
        vpc_cidr           = "10.20.16.0/21"
        private_netmask    = 24
      }
    }
  }
}
```

### Central DNS

By adding a `services.dns` object, the module provisions a central DNS VPC with Route 53 Resolver and domain rules for private hosted zones and split-horizon DNS. See the [terraform-aws-dns](https://github.com/appvia/terraform-aws-dns) module for details.

## Known Limitations

- **Transit Gateway limits**: AWS enforces limits on Transit Gateways, route tables, attachments, and routes per region. Plan CIDR allocation and route table usage accordingly.
- **Trusted layout**: Adding a new trusted attachment requires manual steps—new spokes are associated with the untrusted (workloads) table by default; you must manually move attachments to the trusted table and update `trusted_attachments`.
- **Inspection layout**: The inspection VPC is always provisioned by this module; there is no option to bring an existing inspection attachment. The firewall itself is deployed separately via [terraform-aws-firewall](https://github.com/appvia/terraform-aws-firewall).
- **Endpoints resolver rules**: Sharing resolver rules with spoke VPCs requires consumer-side configuration (associating rule sets). See [terraform-aws-private-endpoints](https://github.com/appvia/terraform-aws-private-endpoints) for details.

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
3. Run `make documentation` (or `terraform-docs .` for the root; module READMEs are generated per `modules/*`)

<!-- BEGIN_TF_DOCS -->
## Providers

No providers.

## Inputs

No inputs.

## Outputs

No outputs.
<!-- END_TF_DOCS -->
