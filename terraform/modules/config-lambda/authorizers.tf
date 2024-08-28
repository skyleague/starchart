output "request_authorizers" {
  value = merge({
    for function_id, definition in local.handlers : definition.authorizer.name => {
        type            = "request"
        function_id     = function_id
        identity_source = try(definition.authorizer.identitySource, null)
        ttl_in_seconds  = try(definition.authorizer.ttlInSeconds, null)
    } if try(definition.authorizer.name, null) != null && try(definition.authorizer.type, "request") == "request"
  })
}