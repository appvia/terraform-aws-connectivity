# Inspection VPC Connectivity Module

The purpose of this module is to create the necessary routing tables and associations for the inspection VPC to communicate with the spoke VPCs.

<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_ec2_transit_gateway_route.inbound](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_transit_gateway_route) | resource |
| [aws_ec2_transit_gateway_route_table.inbound](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_transit_gateway_route_table) | resource |
| [aws_ec2_transit_gateway_route_table.return](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_transit_gateway_route_table) | resource |
| [aws_ec2_transit_gateway_route_table_association.inbound](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_transit_gateway_route_table_association) | resource |
| [aws_ec2_transit_gateway.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ec2_transit_gateway) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_inspection_vpc_attachment_id"></a> [inspection\_vpc\_attachment\_id](#input\_inspection\_vpc\_attachment\_id) | The transit gateway attachment id for the inspection vpc | `string` | `null` | no |
| <a name="input_region"></a> [region](#input\_region) | The region in which the resources will be deployed | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to add to all resources | `map(string)` | n/a | yes |
| <a name="input_transit_gateway_id"></a> [transit\_gateway\_id](#input\_transit\_gateway\_id) | The ID of the transit gateway to provision the routing tables | `string` | n/a | yes |
| <a name="input_transit_gateway_spoke_table_name"></a> [transit\_gateway\_spoke\_table\_name](#input\_transit\_gateway\_spoke\_table\_name) | The name of the transit gateway spoke routing table | `string` | `"spokes"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_inspection_route_table_id"></a> [inspection\_route\_table\_id](#output\_inspection\_route\_table\_id) | The ID of the route table associated with the inspection VPC |
| <a name="output_spokes_route_table_id"></a> [spokes\_route\_table\_id](#output\_spokes\_route\_table\_id) | The ID of the route table associated with the spokey VPC |
<!-- END_TF_DOCS -->

