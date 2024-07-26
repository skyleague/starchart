import { $object, $string, $union } from '@skyleague/therefore'

export const customResource = $object({
    custom: $object({
        arn: $union([$string(), $string().array()]).describe('The ARN of the custom resource.'),
        iamActions: $string().array().describe('Custom IAM actions to add to the role.'),
    }).describe('A custom resource that is used by the function.'),
}).describe('A custom resource that is used by the function.')
