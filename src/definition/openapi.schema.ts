import { $const, $enum, $object, $optional, $record, $string, $union } from '@skyleague/therefore'

export const apiKeySecurityScheme = $object({
    type: $const('apiKey').describe('The type of the security scheme.'),
    description: $string().optional().describe('The description of the security scheme.'),
    name: $string().describe('The name of the API key.'),
    in: $enum(['query', 'header', 'cookie']).describe('The location of the API key.'),
})

export const httpSecurityScheme = $object({
    type: $const('http').describe('The type of the security scheme.'),
    description: $string().optional().describe('The description of the security scheme.'),
    scheme: $string().describe('The name of the HTTP Authorization scheme to be used.'),
    bearerFormat: $string().optional().describe('A hint to the client to identify how the bearer token is formatted.'),
})

export const oauth2SecurityScheme = $object({
    type: $const('oauth2').describe('The type of the security scheme.'),
    description: $string().optional().describe('The description of the security scheme.'),
    flows: $object({
        implicit: $object({
            authorizationUrl: $string().describe('The authorization URL to be used for this flow.'),
            refreshUrl: $string().optional().describe('The URL to be used for obtaining refresh tokens.'),
            scopes: $record($string()).describe('The available scopes for the OAuth2 security scheme.'),
        }).optional(),
        password: $object({
            tokenUrl: $string().describe('The token URL to be used for this flow.'),
            refreshUrl: $string().optional().describe('The URL to be used for obtaining refresh tokens.'),
            scopes: $record($string()).describe('The available scopes for the OAuth2 security scheme.'),
        }).optional(),
        clientCredentials: $object({
            tokenUrl: $string().describe('The token URL to be used for this flow.'),
            refreshUrl: $string().optional().describe('The URL to be used for obtaining refresh tokens.'),
            scopes: $record($string()).describe('The available scopes for the OAuth2 security scheme.'),
        }).optional(),
        authorizationCode: $object({
            authorizationUrl: $string().describe('The authorization URL to be used for this flow.'),
            tokenUrl: $string().describe('The token URL to be used for this flow.'),
            refreshUrl: $string().optional().describe('The URL to be used for obtaining refresh tokens.'),
            scopes: $record($string()).describe('The available scopes for the OAuth2 security scheme.'),
        }).optional(),
    })
        .optional()
        .describe('The available flows for the OAuth2 security scheme.'),
})

export const openIdConnectSecurityScheme = $object({
    type: $const('openIdConnect').describe('The type of the security scheme.'),
    description: $optional($string().describe('The description of the security scheme.')),
    openIdConnectUrl: $string().describe('The OpenID Connect URL to discover OAuth2 configuration values.'),
})

export const securityScheme = $union([
    apiKeySecurityScheme.reference(),
    httpSecurityScheme.reference(),
    oauth2SecurityScheme.reference(),
    openIdConnectSecurityScheme.reference(),
])

export const securityRequirement = $record($string().array().describe('The name of the security scheme.'))
    .array()
    .describe('The security requirements to use for the route.')

export const serverVariable = $object({
    default: $string().describe('The default value to use for substitution.'),
    description: $string().describe('The description of the server variable.').optional(),
    enum: $string()
        .array()
        .describe('An enumeration of string values to be used if the substitution options are from a limited set.')
        .optional(),
})

export const server = $object({
    description: $string().describe('The description of the server.').optional(),
    url: $string().describe('The URL of the server.'),
    variables: $record(serverVariable.reference()).describe('The variables to pass to the server.').optional(),
})

export const servers = server.array().describe('The servers to use for the route.')
