import { $boolean, $object, $optional, $record, $string, $unknown } from '@skyleague/therefore'

export const scheduledTriggerEntry = {
    ruleName: $optional(
        $string({
            description: 'The name to give the scheduled rule. Defaults to prefixing the name of the handler.',
        }),
    ),
    ruleNamePrefix: $string().describe('The prefix to give the scheduled rule. Defaults to the name of the handler.').optional(),
    description: $string().describe('The description to give the scheduled rule.').optional(),
    rate: $string().describe(
        'The rate at which to invoke the handler. Must be a valid rate expression. See https://docs.aws.amazon.com/AmazonCloudWatch/latest/events/ScheduledEvents.html for more information.',
    ),
    enabled: $boolean().describe('Whether the rule should be enabled. Defaults to true.').optional(),
    input: $unknown()
        .describe('The input to pass to the handler. Defaults to an empty object. Conflicts with inputPath and inputTransformer')
        .optional(),
    inputPath: $string({
        description:
            'The JSONPath to use to extract the input to pass to the handler. Conflicts with input and inputTransformer.',
    }).optional(),
    inputTransformer: $object({
        inputPaths: $record($string()).optional().describe('The JSONPaths to use to extract the input to pass to the handler.'),
        inputTemplate: $string().describe('The template to use to transform the input to pass to the handler.'),
    })
        .optional()
        .describe(
            'The input transformer to use to transform the input to pass to the handler. Conflicts with input and inputPath. See https://docs.aws.amazon.com/eventbridge/latest/userguide/eb-transform-target-input.html for more information.',
        ),
}

export const scheduledTrigger = $object({
    schedule: $object(scheduledTriggerEntry).describe('Subscribes to a scheduled event.'),
})
