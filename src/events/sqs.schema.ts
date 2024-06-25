import { $array, $boolean, $enum, $number, $object, $string, $unknown } from '@skyleague/therefore'

export const sqsTrigger = $object({
    sqs: $object({
        queueId: $string().describe('The ID of the SQS queue to subscribe to.'),
        batchSize: $number()
            .optional()
            .describe('The maximum number of messages to retrieve from the queue at once. Default is 1.'),
        fifo: $object({
            enabled: $string().optional().describe('Whether to enable FIFO queue support. Default is false.'),
            contentBasedDeduplication: $boolean()
                .optional()
                .default(true)
                .describe('Whether to enable content-based deduplication. Default is false.'),
            deduplicationScope: $enum(['messageGroup', 'queue'])
                .default('queue')
                .optional()
                .describe('The scope of the deduplication. Default is queue.'),
            throughputLimit: $enum(['perQueue', 'perMessageGroupId'])
                .default('perQueue')
                .optional()
                .describe('The throughput limit of the queue. Default is perQueue.'),
        })
            .optional()
            .describe('The FIFO settings to use when retrieving messages from the queue.'),
        kmsMasterKeyId: $string().optional().describe('The ID of the KMS key to use to decrypt messages.'),
        eventbridge: $object({
            eventBusId: $string().describe('The name of the event bus to subscribe to.'),
            eventPattern: $object({
                'detail-type': $array($unknown()).optional().describe('The detail type of the event.'),
            }).describe('The event pattern to filter on.'),
        })
            .optional()
            .describe('The EventBridge event bus to subscribe to.'),
    }).describe('Subscribes to an SQS queue.'),
})
