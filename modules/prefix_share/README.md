<!-- BEGIN_TF_DOCS -->
## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 5.0.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_resource_share_arn"></a> [resource\_share\_arn](#input\_resource\_share\_arn) | The ARN of the resource share | `string` | n/a | yes |
| <a name="input_principals"></a> [principals](#input\_principals) | The principal to share with | `list(string)` | `[]` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->