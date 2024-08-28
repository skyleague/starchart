import {
    $array,
    $boolean,
    $enum,
    $intersection,
    $number,
    $object,
    $record,
    $ref,
    $string,
    $union,
    $unknown,
} from '@skyleague/therefore'

export const fifoSettings = $object({
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
}).describe('The FIFO settings to use when retrieving messages from the queue.')

export const dlqSettings = $object({
    suffix: $string().optional().describe('The suffix to append to the queue name to create the DLQ.'),
    maxReceiveCount: $number().optional().describe('The maximum number of times to receive a message.'),
    redriveEnabled: $boolean().optional().describe('Whether to enable the redrive policy.'),
    visibilityTimeoutSeconds: $number().optional().describe('The visibility timeout of the DLQ.'),
    messageRetentionPeriodSeconds: $number().optional().describe('The message retention period of the DLQ.'),
    delaySeconds: $number().optional().describe('The delay of the DLQ.'),
    receiveWaitTimeSeconds: $number().optional().describe('The receive wait time of the DLQ.'),
    policy: $string().optional().describe('The policy of the DLQ.'),
}).describe('The dead-letter queue settings to use when messages are not processed.')

export const eventbridgeSettings = $intersection([
    $union([
        $object({
            eventBusId: $string().describe('The name of the event bus to subscribe to.'),
        }),
        $object({
            eventBusName: $string().describe('The name of the event bus to subscribe to.'),
        }),
    ]),
    $object({
        eventPattern: $object({
            'detail-type': $array($unknown()).optional().describe('The detail type of the event.'),
        }).describe('The event pattern to filter on.'),
    }),
]).describe('The EventBridge event bus to subscribe to.')

export const sqsTrigger = $object({
    sqs: $object({
        queueId: $string().describe('The ID of the SQS queue to subscribe to.'),
        batchSize: $number()
            .optional()
            .describe('The maximum number of messages to retrieve from the queue at once. Default is 1.'),
        fifo: $ref(fifoSettings).optional(),
        dlq: $ref(dlqSettings).optional(),
        visibilityTimeoutSeconds: $number().optional().describe('The visibility timeout of the queue.'),
        messageRetentionPeriodSeconds: $number().optional().describe('The message retention period of the queue.'),
        kmsMasterKeyId: $string().optional().describe('The ID of the KMS key to use to decrypt messages.'),
        maxMessageSize: $number().optional().describe('The maximum message size of the queue.'),
        delaySeconds: $number().optional().describe('The delay of the queue.'),
        receiveWaitTimeSeconds: $number().optional().describe('The receive wait time of the queue.'),
        policy: $string().optional().describe('The policy of the queue.'),
        kmsDataKeyReusePeriodSeconds: $number().optional().describe('The data key reuse period of the queue.'),
        tags: $record($string).optional().describe('The tags to apply to the queue.'),
        eventbridge: $ref(eventbridgeSettings).optional(),
    }).describe('Subscribes to an SQS queue.'),
})
