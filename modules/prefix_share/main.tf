
## Share the resource share with each of the principals 
resource "aws_ram_principal_association" "current" {
  for_each = toset(var.principals)

  principal          = each.value
  resource_share_arn = var.resource_share_arn
}

