variable "attachment_id" {
  description = "The transit gateway attachment id for the inspection vpc"
  type        = string
  default     = null
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
}

variable "transit_gateway_id" {
  description = "The ID of the transit gateway to provision the routing tables"
  type        = string
}

variable "transit_gateway_return_table_name" {
  description = "The name of the transit gateway spoke routing table (traffic returning from the inspection vpc)"
  type        = string
}

variable "transit_gateway_inbound_table_name" {
  description = "The name of the transit gateway inbound routing table (traffic going to the inspection vpc)"
  type        = string
}

