resource "aws_resourcegroups_group" "stack" {
  name = try("${var.config.stack_name}-${lower(var.default_tags["StackType"])}", var.config.stack_name)
  tags = {
    Name  = var.config.project_name
    Stack = ""
  }

  resource_query {
    query = jsonencode({
      ResourceTypeFilters = ["AWS::AllSupported"],
      TagFilters = concat(
        [
          {
            Key    = "Name"
            Values = [var.config.project_name]
          },
          {
            Key    = "Stack"
            Values = [var.config.stack_name]
          },
        ],
        try([{
          Key    = "StackType"
          Values = [var.default_tags["StackType"]]
          }
        ], [])
      )
    })
  }
}
