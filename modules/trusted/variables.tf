
variable "amazon_side_asn" {
  description = "The ASN for the transit gateway."
  type        = number

  validation {
    condition     = var.amazon_side_asn >= 64512 && var.amazon_side_asn <= 65534
    error_message = "The ASN must be in the private range of 64512 to 65534."
  }
}

variable "services" {
  description = "A collection of features and services associated with this connectivity domain."
  type = object({

    egress = optional(object({
      network = object({
        # Defines the configuration for an egress network.
        availability_zones = optional(number, 2)
        # The number of availablity zones to use for the egress network. Defaults to 2.
        ipam_pool_id = optional(string, null)
        # The ID of the IPAM pool to use for the egress network. Defaults to null.
        name = optional(string, "egress")
        # The name of the egress network. Defaults to 'egress'.
        private_netmask = optional(number, 28)
        # The netmask to use for the private network. Defaults to 28.
        public_netmask = optional(number, 28)
        # The netmask to use for the public network. Defaults to 28.
        transit_gateway_routes = optional(map(string), {
          private = "10.0.0.0/8"
          public  = "10.0.0.0/8"
        })
        # The transit gateway route tables entries for the egress network.
        vpc_cidr = optional(string, null)
        # The CIDR block to use for the VPC. Defaults to null, required when not using IPAM
        vpc_netmask = optional(string, null)
        # The netmask to use for the VPC. Defaults to null, required when using IPAM
      })
    }), null)

    dns = optional(object({
      # The list of organizational units or accounts to share the domain rule with.
      resolver_name = optional(string, "dns-resolver")

      # Defines the configuration for the endpoints network.
      network = object({
        # Defines the configuration for the endpoints network.
        availability_zones = optional(number, 2)
        # The number of availablity zones to use for the endpoints network. Defaults to 2.
        ipam_pool_id = optional(string, null)
        # The ID of the IPAM pool to use for the endpoints network. Defaults to null.
        name = optional(string, "central-dns")
        # The name of the endpoints network. Defaults to 'endpoints'.
        private_netmask = optional(number, 24)
        # The netmask to use for the private network. Defaults to 24, ensure space for enough aws services.
        vpc_cidr = optional(string, null)
        # The CIDR block to use for the VPC. Defaults to null, required when not using IPAM
        vpc_netmask = optional(string, null)
        # The netmask to use for the VPC. Defaults to null, required when using IPAM
      }),

      domain_rules = optional(list(object({
        ram_share_name = optional(string, "central-dns")
        # The name of the domain rule - this is mapped to the resource share name
        ram_principals = optional(map(string), {})
        # The name of the resolver to use. Defaults to 'dns-resolver'.
        rules = list(object({
          name = string
          # The name of the rule - the ram share name is domain.name + "-" + rule.name
          # The list of domain rules to apply to the domain.
          domain = string
          # The domain to apply the rule to.
          targets = optional(list(string), [])
          # The list of targets to apply the rule to - defaults to local resolver.
        }))
      })), [])
    }), null)
    ## Centralized DNS, used to house central DNS resolvers and rules

    endpoints = optional(object({
      # Defines the configuration for the endpoints network.
      network = object({
        # Defines the configuration for the endpoints network.
        availability_zones = optional(number, 2)
        # The number of availablity zones to use for the endpoints network. Defaults to 2.
        ipam_pool_id = optional(string, null)
        # The ID of the IPAM pool to use for the endpoints network. Defaults to null.
        name = optional(string, "endpoints")
        # The name of the endpoints network. Defaults to 'endpoints'.
        private_netmask = optional(number, 24)
        # The netmask to use for the private network. Defaults to 24, ensure space for enough aws services.
        vpc_cidr = optional(string, null)
        # The CIDR block to use for the VPC. Defaults to null, required when not using IPAM
        vpc_netmask = optional(string, null)
        # The netmask to use for the VPC. Defaults to null, required when using IPAM
      })

      resolver_rules = optional(object({
        # Defines the configuration for the sharing network via AWS RAM
        principals = optional(list(string), [])
        # The list of organizational units or accounts to share the endpoints resolvers rules with. Defaults to an empty list.
      }), null)

      resolver = optional(object({
        enable = optional(bool, false)
        # Whether to enable the resolver. Defaults to false.
      }), null)

      services = optional(map(object({
        # Whether private DNS is enabled. Defaults to true.
        service_type = optional(string, "Interface")
        # The type of service, i.e. Gateway or Interface. Defaults to 'Interface'
        service = string
        # The name of the service i.e. ec2, ec2messages, ssm, ssmmessages, logs, kms, secretsmanager, s3.awsamazon.com
        policy = optional(string, null)
        # An optional IAM policy to use for the endpoint. Defaults to null.
        })), {
        ec2messages = {
          service = "ec2messages"
        },
        ssm = {
          service = "ssm"
        },
        ssmmessages = {
          service = "ssmmessages"
        },
      })
    }), null)
    ## Centralized private endpoints, using route53 resolver rules instead of private hosted zones

    ingress = optional(object({
      # Defines the configuration for the ingress network.
      network = object({
        # Defines the configuration for the ingress network.
        availability_zones = optional(number, 2)
        # The number of availablity zones to use for the ingress network. Defaults to 2.
        ipam_pool_id = optional(string, null)
        # The ID of the IPAM pool to use for the ingress network. Defaults to null.
        name = optional(string, "ingress")
        # The name of the ingress network. Defaults to 'ingress'.
        private_netmask = number
        # The netmask to use for the private network. Required, ensure space for enough aws services.
        public_netmask = number
        # The netmask to use for the public network. Required, ensure space for enough aws services.
        transit_gateway_routes = optional(map(string), {
          private = "10.0.0.0/8"
          public  = "10.0.0.0/8"
        })
        # The transit gateway route tables entries for the ingress network.
        vpc_cidr = optional(string, null)
        # The CIDR block to use for the VPC. Defaults to null, required when not using IPAM
        vpc_netmask = optional(string, null)
        # The netmask to use for the VPC. Defaults to null, required when using IPAM
      })
    }), null)
    ## Centralized ingress network, used to house all the ingress endpoints
  })
  default = {}
}

variable "connectivity_config" {
  description = "The type of connectivity options for the transit gateway."
  type = object({
    # Defines the configuration for the trusted routing
    trusted_attachments = optional(map(string), {})
    # The list of transit gateway attachments to trust e.g can see all the other untrusted networks. Defaults to an empty list.
    trusted_route_table_name = optional(string, "trusted")
    # The name of the trusted route table. Defaults to 'trusted'.
    trusted_core_route_table_name = optional(string, "trusted-core")
    # The name of the trusted core route table. Defaults to 'trusted-core' (used for future expansion).
  })
}

variable "description" {
  description = "The description of the transit gateway to provision."
  type        = string
}

variable "enable_dns_support" {
  description = "Whether DNS support is enabled."
  type        = bool
  default     = true
}

variable "enable_external_principals" {
  description = "Whether to enable external principals in the RAM share."
  type        = bool
  default     = true
}

variable "enable_multicast_support" {
  description = "Whether multicast support is enabled."
  type        = bool
  default     = false
}

variable "enable_vpn_ecmp_support" {
  description = "Whether VPN Equal Cost Multipath Protocol support is enabled."
  type        = bool
  default     = false
}

variable "transit_ssm_parameter_prefix" {
  description = "The name of the SSM parameter to create for the transit gateway ID."
  type        = string
  default     = "/landing-zone"
}

variable "enable_ssm_sharing" {
  description = "Whether to create and share the SSM parameter for the transit gateway ID."
  type        = bool
  default     = false
}

variable "name" {
  description = "The name of the transit gateway to provision."
  type        = string
  default     = "tgw"
}

variable "ram_share_name" {
  description = "The name of the RAM share to create for the transit gateway."
  type        = string
  default     = "tgw-ram-share"
}

variable "ram_share_principals" {
  description = "The list of organizational units or accounts to share the transit gateway with."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "A map of tags to add to all resources."
  type        = map(string)
}
