variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
}

variable "trusted_attachments" {
  description = "A list of transit gateway attachment IDs to associate with the trusted routing table"
  type        = list(string)
  default     = []
}

variable "transit_gateway_id" {
  description = "The ID of the transit gateway to provision the routing tables"
  type        = string
}

variable "transit_gateway_trusted_table_name" {
  description = "The name of the transit gateway spoke routing table (traffic returning from the inspection vpc)"
  type        = string
}
