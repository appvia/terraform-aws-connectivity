<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0.7 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.0.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 5.0.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_ram_principal_association.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ram_principal_association) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_resource_share_arn"></a> [resource\_share\_arn](#input\_resource\_share\_arn) | The ARN of the resource share | `string` | n/a | yes |
| <a name="input_principals"></a> [principals](#input\_principals) | The principal to share with | `list(string)` | `[]` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->