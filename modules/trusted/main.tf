
## Share the transit gateway with the other principals
resource "aws_ram_principal_association" "associations" {
  for_each = toset(var.ram_share_principals)

  principal          = each.value
  resource_share_arn = module.tgw.ram_resource_share_id
}
