import { httpTrigger } from './http.schema.js'
import { scheduledTrigger } from './scheduled.schema.js'
import { sqsTrigger } from './sqs.schema.js'

import { $ref, $union } from '@skyleague/therefore'

export const events = $union([$ref(httpTrigger), $ref(sqsTrigger), $ref(scheduledTrigger)])
    .describe('The events that will trigger the handler.')
    .array()
