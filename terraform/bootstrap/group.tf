resource "aws_resourcegroups_group" "application" {
  name = local.config.project_name
  tags = {
    Name = ""
  }

  resource_query {
    query = jsonencode({
      ResourceTypeFilters = ["AWS::AllSupported"],
      TagFilters = [
        {
          Key    = "Name"
          Values = [local.config.project_name]
        },
      ]
    })
  }
}
