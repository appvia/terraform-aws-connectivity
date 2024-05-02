
variable "amazon_side_asn" {
  description = "The ASN for the transit gateway."
  type        = number

  validation {
    condition     = var.amazon_side_asn >= 64512 && var.amazon_side_asn <= 65534
    error_message = "The ASN must be in the private range of 64512 to 65534."
  }
}

variable "prefix_lists" {
  description = "Provides the ability to provision prefix lists, and share them with other accounts."
  type = list(object({
    name = string
    entry = list(object({
      address_family = optional(string, "IPv4")
      cidr           = string
      description    = string
      max_entries    = number
    }))
  }))
  default = []
}

variable "prefix_ram_principals" {
  description = "The list of organizational units or accounts to share the prefix lists with."
  type        = list(string)
  default     = []
}

variable "connectivity_config" {
  description = "The type of connectivity options for the transit gateway."
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
        vpc_cidr = optional(string, null)
        # The CIDR block to use for the VPC. Defaults to null, required when not using IPAM
        vpc_netmask = optional(string, null)
        # The netmask to use for the VPC. Defaults to null, required when using IPAM
      })
    }), null)
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
      sharing = optional(object({
        # Defines the configuration for the sharing network via AWS RAM 
        principals = optional(list(string), [])
        # The list of organizational units or accounts to share the endpoints resolvers rules with. Defaults to an empty list.
      }), null)
      services = optional(map(object({
        # Defines the configuration for the private endpoints in the shared network. 
        private_dns_enabled = optional(bool, true)
        # Whether private DNS is enabled. Defaults to true. 
        service_type = optional(string, "Interface")
        # The type of service, i.e. Gateway or Interface. Defaults to 'Interface'
        service = string
        # The name of the service i.e. ec2, ec2messages, ssm, ssmmessages, logs, kms, secretsmanager, s3.awsamazon.com
        policy = optional(string, null)
        # An optional IAM policy to use for the endpoint. Defaults to null.
        })), {
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
      })
    }), null)
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
        vpc_cidr = optional(string, null)
        # The CIDR block to use for the VPC. Defaults to null, required when not using IPAM 
        vpc_netmask = optional(string, null)
        # The netmask to use for the VPC. Defaults to null, required when using IPAM 
      })
    }), null)
    inspection = optional(object({
      # Defines the configuration for the inspection network. 
      inbound_route_table_name = optional(string, "inbound")
      # The name of the inbound route table. Defaults to 'inbound'. 
      network = optional(object({
        # Defines the configuration for the inspection network. 
        availability_zones = number
        # The number of availablity zones to use for the inspection network. Required. Must match the 
        # number of availability zones you use in the organization, due to symmetric routing requirements. 
        name = optional(string, "inspection")
        # The name of the inspection network. Defaults to 'inspection'. 
        private_netmask = optional(number, 24)
        # The netmask to use for the private network. Defaults to 24
        vpc_cidr = optional(string, "100.64.0.0/21")
        # The CIDR block to use for the VPC. Defaults to carrier-grade NAT space. 
      }), null)
      spokes_route_table_name = optional(string, "spokes")
      # The name of the spokes route table. Defaults to 'spokes'. 
    }), null)
    trusted = optional(object({
      # Defines the configuration for the trusted routing
      trusted_attachments = optional(list(string), [])
      # The list of transit gateway attachments to trust e.g can see all the other untrusted networks. Defaults to an empty list.
      trusted_route_table_name = optional(string, "trusted")
      # The name of the trusted route table. Defaults to 'trusted'.
    }), null)
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
