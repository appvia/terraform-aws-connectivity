
## SSM Parameters for VPC and Transit Gateway IDs
resource "aws_ssm_parameter" "transit_gateway_id" {
  count = var.enable_ssm_sharing ? 1 : 0

  name        = format(var.transit_ssm_parameter_name, var.region)
  description = "Contains the Transit Gateway ID for region ${var.region}"
  type        = "String"
  value       = var.transit_gateway_id
  tags        = var.tags
}

## Share the SSM Parameter using RAM
module "transit_gateway_ssm_share" {
  count   = var.enable_ssm_sharing ? 1 : 0
  source  = "appvia/ram/aws"
  version = "0.0.1"

  allow_external_principals = false
  name                      = "transit-gateway-ssm-${var.region}"
  principals                = var.ram_share_principals
  resource_arns             = [aws_ssm_parameter.transit_gateway_id.arn]
  tags                      = var.tags
}

