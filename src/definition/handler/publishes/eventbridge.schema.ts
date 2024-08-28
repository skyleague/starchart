import { $object, $string, $union } from '@skyleague/therefore'

export const publishEventbridge = $object({
    eventbridge: $object({
        eventBusId: $string().describe('The name of the event bus to publish to.'),
        detailType: $union([$string, $string().array()]).describe('The detail type of the event.'),
    }).describe('Publishes an event to an EventBridge event bus.'),
})
