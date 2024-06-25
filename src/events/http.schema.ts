import { $enum, $object, $optional, $string } from '@skyleague/therefore'

export const httpTrigger = $object({
    http: $object({
        method: $enum(['get', 'post', 'put', 'delete', 'patch', 'options', 'head']),
        path: $string().describe('The HTTP path for the route. Must start with / and must not end with /.'),
        authorizer: $optional($string().describe('The name of the authorizer to use for the route.').optional()),
    }).describe('Subscribes to an HTTP route.'),
})
