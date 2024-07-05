/**
 * Generated by @skyleague/therefore@v1.0.0-local
 * Do not manually touch this
 */
/* eslint-disable */

/**
 * The dead-letter queue settings to use when messages are not processed.
 */
export interface DlqSettings {
    /**
     * The suffix to append to the queue name to create the DLQ.
     */
    suffix?: string | undefined
    /**
     * The maximum number of times to receive a message.
     */
    maxReceiveCount?: number | undefined
    /**
     * Whether to enable the redrive policy.
     */
    redriveEnabled?: boolean | undefined
    /**
     * The visibility timeout of the DLQ.
     */
    visibilityTimeoutSeconds?: number | undefined
    /**
     * The message retention period of the DLQ.
     */
    messageRetentionPeriodSeconds?: number | undefined
    /**
     * The delay of the DLQ.
     */
    delaySeconds?: number | undefined
    /**
     * The receive wait time of the DLQ.
     */
    receiveWaitTimeSeconds?: number | undefined
    /**
     * The policy of the DLQ.
     */
    policy?: string | undefined
}

/**
 * The EventBridge event bus to subscribe to.
 */
export interface EventbridgeSettings {
    /**
     * The name of the event bus to subscribe to.
     */
    eventBusId: string
    /**
     * The event pattern to filter on.
     */
    eventPattern: {
        /**
         * The detail type of the event.
         */
        'detail-type'?: unknown[] | undefined
    }
}

/**
 * The FIFO settings to use when retrieving messages from the queue.
 */
export interface FifoSettings {
    /**
     * Whether to enable FIFO queue support. Default is false.
     */
    enabled?: string | undefined
    /**
     * Whether to enable content-based deduplication. Default is false.
     *
     * @default true
     */
    contentBasedDeduplication?: boolean | undefined
    /**
     * The scope of the deduplication. Default is queue.
     *
     * @default 'queue'
     */
    deduplicationScope?: 'messageGroup' | 'queue' | undefined
    /**
     * The throughput limit of the queue. Default is perQueue.
     *
     * @default 'perQueue'
     */
    throughputLimit?: 'perQueue' | 'perMessageGroupId' | undefined
}

export interface SqsTrigger {
    /**
     * Subscribes to an SQS queue.
     */
    sqs: {
        /**
         * The ID of the SQS queue to subscribe to.
         */
        queueId: string
        /**
         * The maximum number of messages to retrieve from the queue at once. Default is 1.
         */
        batchSize?: number | undefined
        fifo?: FifoSettings | undefined
        dlq?: DlqSettings | undefined
        /**
         * The visibility timeout of the queue.
         */
        visibilityTimeoutSeconds?: number | undefined
        /**
         * The message retention period of the queue.
         */
        messageRetentionPeriodSeconds?: number | undefined
        /**
         * The ID of the KMS key to use to decrypt messages.
         */
        kmsMasterKeyId?: string | undefined
        /**
         * The maximum message size of the queue.
         */
        maxMessageSize?: number | undefined
        /**
         * The delay of the queue.
         */
        delaySeconds?: number | undefined
        /**
         * The receive wait time of the queue.
         */
        receiveWaitTimeSeconds?: number | undefined
        /**
         * The policy of the queue.
         */
        policy?: string | undefined
        /**
         * The data key reuse period of the queue.
         */
        kmsDataKeyReusePeriodSeconds?: number | undefined
        /**
         * The tags to apply to the queue.
         */
        tags?:
            | {
                  [k: string]: string | undefined
              }
            | undefined
        eventbridge?: EventbridgeSettings | undefined
    }
}
