import { $object, $record, $string } from '@skyleague/therefore'

export const starchart = $object({
    project: $object({
        name: $string().describe('The name of the project.'),
        identifier: $string().describe('The identifier of the project.'),
    }),

    params: $record($record($string())).optional().describe('The parameters to be used when rendering the handler definition.'),

    stacks: $record(
        $object({
            path: $string().describe('The path to the stack.'),
        }),
    ).describe('The stacks to deploy.'),
}).validator({ compile: false })
