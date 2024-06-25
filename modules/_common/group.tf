resource "aws_resourcegroups_group" "stack" {
  count = var.default_tags["StackType"] != null ? 1 : 0
  name  = "${var.config.stack}-${lower(var.default_tags["StackType"])}"
  tags = {
    Name  = var.config.project_name
    Stack = ""
  }

  resource_query {
    query = jsonencode({
      ResourceTypeFilters = ["AWS::AllSupported"],
      TagFilters = [
        {
          Key    = "Name"
          Values = [var.config.project_name]
        },
        {
          Key    = "Stack"
          Values = [var.config.stack]
        },
        {
          Key    = "StackType"
          Values = [var.default_tags["StackType"]]
        }
      ]
    })
  }
}
