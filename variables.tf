
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
      attachment_id = optional(string, "")
      network = optional(object({
        availability_zones = number
        ipam_pool_id       = optional(string, null)
        name               = optional(string, "egress")
        vpc_cidr           = optional(string, null)
        vpc_netmask        = optional(string, null)
      }), null)
    }), null)
    ingress = optional(object({
      attachment_id = optional(string, "")
      network = optional(object({
        availability_zones = number
        ipam_pool_id       = optional(string, null)
        name               = optional(string, "ingress")
        private_netmask    = optional(number, null)
        public_netmask     = optional(number, null)
        vpc_cidr           = optional(string, null)
        vpc_netmask        = optional(string, null)
      }), null)
    }), null)
    inspection = optional(object({
      attachment_id            = optional(string, "")
      inbound_route_table_name = optional(string, "inbound")
      spokes_route_table_name  = optional(string, "spokes")
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
  default     = "tgw-hub"
}

variable "ram_share_name" {
  description = "The name of the RAM share to create for the transit gateway."
  type        = string
  default     = "tgw-hub-ram-share"
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

