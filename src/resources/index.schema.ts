import { dynamodbResource } from './dynamodb.schema.js'
import { parameterResource } from './parameter.schema.js'
import { s3Resource } from './s3.schema.js'
import { secretResource } from './secret.schema.js'

import { $ref, $union } from '@skyleague/therefore'

export const resources = $union([$ref(dynamodbResource), $ref(secretResource), $ref(parameterResource), $ref(s3Resource)])
    .array()
    .describe('The resources that the function will use.')
