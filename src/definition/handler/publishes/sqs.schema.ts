import { $object, $string } from '@skyleague/therefore'

export const publishSqs = $object({
    sqs: $object({
        queueId: $string().describe('The ID of the SQS queue to publish to.'),
    }),
}).describe('Publishes an event to an SQS queue.')
