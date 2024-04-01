
variable "resource_share_arn" {
  description = "The ARN of the resource share"
  type        = string
}

variable "principals" {
  description = "The principal to share with"
  type        = list(string)
  default     = []
}
