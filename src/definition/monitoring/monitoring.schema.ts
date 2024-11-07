import { $object, type ObjectType } from '@skyleague/therefore'
import { apigatewayMonitoring, sqsMonitoring } from './metrics.schema.js'

export const monitoring: ObjectType = $object({
    httpApi: apigatewayMonitoring,
    restApi: apigatewayMonitoring,
    sqs: sqsMonitoring,
}).partial()
