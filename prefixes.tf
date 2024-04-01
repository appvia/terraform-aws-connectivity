
## Provision the prefix lists within the account 
resource "aws_ec2_managed_prefix_list" "prefixes" {
  for_each = { for prefix in var.prefix_lists : prefix.name => prefix }

  name           = each.value.name
  address_family = "IPv4"
  max_entries    = each.value.max_entries
  tags           = var.tags

  dynamic "entry" {
    for_each = each.value.entries

    content {
      cidr        = entry.value.cidr
      description = entry.value.description
    }
  }
}

## Provision the prefix ram shares within the account
resource "aws_ram_resource_share" "prefixes" {
  for_each = { for prefix in var.prefix_lists : prefix.name => prefix }

  allow_external_principals = true
  name                      = format("prefix-%s", each.value.name)
  tags                      = var.tags
}

## Associate the resource and the share together 
resource "aws_ram_resource_association" "prefixes" {
  for_each = { for prefix in var.prefix_lists : prefix.name => prefix }

  resource_arn       = aws_ec2_managed_prefix_list.prefixes[each.key].arn
  resource_share_arn = aws_ram_resource_share.prefixes[each.key].arn
}

## Share the prefixes with the ram principals 
module "share_prefixes" {
  for_each = { for prefix in var.prefix_lists : prefix.name => prefix }
  source   = "./modules/prefix_share"

  principals         = var.prefix_ram_principals
  resource_share_arn = each.value.arn
}


