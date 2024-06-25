import { publishEventbridge } from './eventbridge.schema.js'
import { publishSqs } from './sqs.schema.js'

import { $ref, $union } from '@skyleague/therefore'

export const publishes = $union([$ref(publishEventbridge), $ref(publishSqs)])
    .array()
    .describe('The events that the handler may publish.')
