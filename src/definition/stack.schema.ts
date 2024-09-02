import { $boolean, $const, $intersection, $number, $object, $record, $string, $union } from '@skyleague/therefore'
import { starChartHandler } from './handler.schema.js'
import { securityScheme, servers } from './openapi.schema.js'

export const requestAuthorizer = $intersection([
    $object({
        type: $const('request').describe('The type of the authorizer.'),
        ttlInSeconds: $number().optional().default(60).describe('The TTL for the authorizer.'),
        identitySource: $string().array().optional().describe('The identity source for the authorizer.'),

        securityScheme: securityScheme.reference().optional().describe('The security requirements to use for the route.'),
    }),
    $union([
        $object({
            functionId: $string().optional().describe('The function ID for the authorizer.'),
        }),
        $object({
            functionName: $string().optional().describe('The function arn for the authorizer.'),
        }),
    ]),
])
export const jwtAuthorizer = $intersection([
    $object({
        type: $const('jwt').describe('The type of the authorizer.'),
        identitySource: $string().optional().describe('The identity source for the authorizer.'),
        ttlInSeconds: $number().optional().default(60).describe('The TTL for the authorizer.'),
        issuer: $string().describe('The issuer for the authorizer.'),
        audience: $string().array().describe('The audience for the authorizer.'),

        securityScheme: securityScheme.reference().optional().describe('The security requirements to use for the route.'),
    }),
])
export const httpApiRequestAuthorizer = $intersection([
    requestAuthorizer.reference(),
    $object({
        enableSimpleResponses: $boolean().optional().default(true).describe('Enable simple responses for the authorizer.'),
        payloadFormatVersion: $string().optional().default('2.0').describe('The payload format version for the authorizer.'),
    }),
])

export const apigateway = $object({
    name: $string().optional().describe('The name of the API Gateway, defaults to the stack name.'),
    deferDeployment: $boolean().optional().default(false).describe('Defer deployment of the API to a later stage.'),
    disableExecuteApiEndpoint: $boolean().optional().default(true).describe('Disable the execute-api endpoint.'),
    authorizers: $record($union([httpApiRequestAuthorizer.reference(), jwtAuthorizer.reference()]))
        .optional()
        .default({})
        .describe('Map of authorizers for the API.'),
    defaultAuthorizer: $object({
        name: $string().describe('The default authorizer for the API.'),
        scopes: $string().array().optional().describe('The default scopes for the API.'),
    })
        .optional()
        .describe('The default authorizer for the API.'),
})

export const stack = $object({
    httpApi: apigateway.reference().optional(),
    restApi: apigateway.reference().optional(),

    lambda: $object({
        runtime: starChartHandler.shape.runtime.optional(),
        memorySize: starChartHandler.shape.memorySize.optional(),
        timeout: starChartHandler.shape.timeout.optional(),
        handler: starChartHandler.shape.handler.optional(),
        vpcConfig: starChartHandler.shape.vpcConfig.optional(),

        environment: starChartHandler.shape.environment.optional(),
        inlinePolicies: starChartHandler.shape.inlinePolicies.optional(),

        functionsDir: $string().optional().describe('The directory containing the functions to be deployed.'),
        functionPrefix: $string().optional().describe('The prefix to be used when naming the functions.'),
        handlerFile: $string()
            .optional()
            .default('handler.yml')
            .describe('The name of the file containing the handler definition.'),
    })
        .optional()
        .default({})
        .describe('The configuration for the lambda runtime.'),

    params: $record($record($string())).optional().describe('The parameters to be used when rendering the handler definition.'),

    openapi: $object({
        servers: servers.optional(),
        // disable these for now, as the values can all be inferred from the starchart definition
        // security: securityRequirement.reference().optional(),
        // securitySchemes: $record(securityScheme.reference()).optional().describe('The security schemes to use for the route.'),
    })
        .optional()
        .describe('The configuration for the OpenAPI.'),
}).validator({ compile: false })
