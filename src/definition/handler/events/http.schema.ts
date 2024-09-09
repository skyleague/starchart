import { $enum, $object, $string } from '@skyleague/therefore'
export const httpTrigger = $object({
    http: $object({
        method: $enum(['get', 'post', 'put', 'delete', 'patch', 'options', 'head']),
        path: $string().describe('The HTTP path for the route. Must start with / and must not end with /.'),

        authorizer: $object({
            name: $string().describe('The name of the authorizer to use for the route.'),
            scopes: $string().array().optional().describe('The scopes to use for the authorizer.'),
        })
            .optional()
            .describe('The authorizer to use for the route, this overrides the default authorizer.'),
    }).describe('Subscribes to an HTTP route.'),
})