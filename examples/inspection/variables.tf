
variable "name" {
  description = "The name of the transit gateway to provision."
  type        = string
  default     = "main-hub"
}

variable "asn" {
  description = "The ASN of the gateway."
  type        = number
  default     = 64512

  validation {
    condition     = var.asn > 0 && var.asn < 4294967296
    error_message = "The ASN must be between 1 and 4294967295."
  }
}

variable "tags" {
  description = "A map of tags to assign to the resources."
  type        = map(string)
  default = {
    Environment = "Production"
    GitRepo     = "https://github.com/appvia/terraform-aws-connectivity"
    Owner       = "Engineering"
    Product     = "Networking"
  }
}
