import { $enum, $number, $object, $optional, $record, $ref, $string, $union, $unknown } from '@skyleague/therefore'
import { events } from './handler/events/index.schema.js'
import { scheduledTriggerEntry } from './handler/events/scheduled.schema.js'
import { publishes } from './handler/publishes/index.schema.js'
import { resources } from './handler/resources/index.schema.js'
import { securityScheme } from './openapi.schema.js'

export const starChartHandler = $object({
    handler: $string().optional().describe('The name of the handler function to invoke.'),
    functionId: $string().optional().describe('The ID of the function. Defaults to the name of the folder.'),
    functionName: $string().optional().describe('The name of the function. Defaults to the function ID.'),
    environment: $record($string()).optional().describe('The environment variables to set for the handler.'),
    warmer: $optional(
        $object({
            ...scheduledTriggerEntry,
            rate: scheduledTriggerEntry.rate.optional(),
        }).describe('The warmer to use to keep the handler warm. Defaults to enabled, rate: 10 minutes.'),
    ),
    events: $ref(events).optional(),
    publishes: $ref(publishes).optional(),
    resources: $ref(resources).optional(),

    inlinePolicies: $union([$record($unknown), $string])
        .array()
        .optional(),
    runtime: $enum(['nodejs18.x', 'nodejs20.x', 'python3.8', 'python3.9', 'python3.10']).optional(),
    memorySize: $number().optional(),
    timeout: $number().optional(),
    vpcConfig: $string().optional(),

    authorizer: $object({
        name: $string().describe('The name of the authorizer to use for the route.'),
        securityScheme: securityScheme.reference().optional().describe('The security schemes to use for the route.'),
    })
        .optional()
        .describe('Define that this lambda defines an authorizer.'),
})
    .describe('The definition of a Star Chart handler.')
    .validator({ compile: false })
