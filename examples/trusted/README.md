<!-- BEGIN_TF_DOCS -->
## Providers

No providers.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_asn"></a> [asn](#input\_asn) | The ASN of the gateway. | `number` | `64512` | no |
| <a name="input_name"></a> [name](#input\_name) | The name of the transit gateway to provision. | `string` | `"main-hub"` | no |
| <a name="input_ram_principals"></a> [ram\_principals](#input\_ram\_principals) | The AWS RAM principal to share the transit gateway with. | `map(string)` | `{}` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to assign to the resources. | `map(string)` | `{}` | no |
| <a name="input_trusted_attachments"></a> [trusted\_attachments](#input\_trusted\_attachments) | The list of trusted account IDs. | `map(string)` | `{}` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->