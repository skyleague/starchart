import { events } from './events/index.schema.js'
import { scheduledTriggerEntry } from './events/scheduled.schema.js'
import { publishes } from './publishes/index.schema.js'
import { resources } from './resources/index.schema.js'

import { $enum, $number, $object, $optional, $record, $ref, $string } from '@skyleague/therefore'

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

    inlinePolicies: $string().array().optional(),
    runtime: $enum(['nodejs16.x', 'nodejs18.x', 'python3.8', 'python3.9', 'python3.10']).optional(),
    memorySize: $number().optional(),
    timeout: $number().optional(),
    vpcConfig: $string().optional(),
})
    .describe('The definition of a Star Chart handler.')
    .validator({ compile: false })
