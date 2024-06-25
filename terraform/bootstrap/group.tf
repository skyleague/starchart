resource "aws_resourcegroups_group" "application" {
  name = module.config.project_name
  tags = {
    Name = ""
  }

  resource_query {
    query = jsonencode({
      ResourceTypeFilters = ["AWS::AllSupported"],
      TagFilters = [
        {
          Key    = "Name"
          Values = [module.config.project_name]
        },
      ]
    })
  }
}
