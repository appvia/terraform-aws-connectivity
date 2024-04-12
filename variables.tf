
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
        availability_zones = optional(number, 2)
        ipam_pool_id       = optional(string, null)
        name               = optional(string, "egress")
        private_netmask    = optional(number, 28)
        public_netmask     = optional(number, 28)
        vpc_cidr           = optional(string, null)
        vpc_netmask        = optional(string, null)
      })
    }), null)
    endpoints = optional(object({
      network = object({
        availability_zones = optional(number, 2)
        ipam_pool_id       = optional(string, null)
        name               = optional(string, "endpoints")
        private_netmask    = optional(number, 24)
        vpc_cidr           = optional(string, null)
        vpc_netmask        = optional(string, null)
      })
      sharing = optional(object({
        principals = optional(list(string), [])
      }), null)
      services = optional(map(object({
        private_dns_enabled = optional(bool, true)
        service_type        = optional(string, "Interface")
        service             = string
        policy              = optional(string, null)
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
      network = object({
        availability_zones = optional(number, 2)
        ipam_pool_id       = optional(string, null)
        name               = optional(string, "ingress")
        private_netmask    = number
        public_netmask     = number
        vpc_cidr           = optional(string, null)
        vpc_netmask        = optional(string, null)
      })
    }), null)
    inspection = optional(object({
      inbound_route_table_name = optional(string, "inbound")
      network = optional(object({
        availability_zones = number
        name               = optional(string, "inspection")
        private_netmask    = optional(number, 24)
        vpc_cidr           = optional(string, "100.64.0.0/21")
      }), null)
      spokes_route_table_name = optional(string, "spokes")
    }), null)
    trusted = optional(object({
      trusted_attachments      = optional(list(string), [])
      trusted_route_table_name = optional(string, "trusted")
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
