
## SSM Parameters for VPC and Transit Gateway IDs
resource "aws_ssm_parameter" "transit_gateway_id" {
  count = var.enable_ssm_sharing ? 1 : 0

  name        = format("%s/%s/id", var.transit_ssm_parameter_prefix, local.region)
  description = "Contains the Transit Gateway ID for region ${local.region}"
  type        = "String"
  value       = module.tgw.ec2_transit_gateway_id
  tags        = var.tags
}

resource "aws_ssm_parameter" "transit_gateway_arn" {
  count = var.enable_ssm_sharing ? 1 : 0

  name        = format("%s/%s/arn", var.transit_ssm_parameter_prefix, local.region)
  description = "Contains the Transit Gateway ARN for region ${local.region}"
  type        = "String"
  value       = module.tgw.ec2_transit_gateway_arn
  tags        = var.tags
}

## Share the SSM Parameter using RAM
module "transit_gateway_ssm_share" {
  count   = var.enable_ssm_sharing ? 1 : 0
  source  = "appvia/ram/aws"
  version = "0.0.1"

  allow_external_principals = false
  name                      = format("transit-gateway-ssm-%s", local.region)
  principals                = var.ram_share_principals
  tags                      = var.tags

  resource_arns = [
    aws_ssm_parameter.transit_gateway_arn.arn,
    aws_ssm_parameter.transit_gateway_id.arn,
  ]
}

