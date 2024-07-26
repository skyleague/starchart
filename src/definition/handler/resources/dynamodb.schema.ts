import { $enum, $object, $string } from '@skyleague/therefore'

export const dynamodbResource = $object({
    dynamodb: $object({
        tableId: $string().describe('The ID of the table.'),
        actions: $enum(['read', 'write', 'scan', 'delete', 'put', 'update', 'get', 'query'])
            .array({ minItems: 1 })
            .describe('The actions to allow on the table.'),
        iamActions: $string().array().optional().describe('Custom IAM actions to add to the role.'),
    }).describe('A DynamoDB table that is used by the function.'),
}).describe('A DynamoDB table that is used by the function.')
