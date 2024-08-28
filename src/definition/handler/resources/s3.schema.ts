import { $enum, $object, $string } from '@skyleague/therefore'

export const s3Resource = $object({
    s3: $object({
        bucketId: $string().describe('The ID of the bucket.'),
        actions: $enum(['read', 'write', 'delete', 'get', 'list']).array({ minItems: 1 }),
        iamActions: $string().array().optional().describe('Custom IAM actions to add to the role.'),
    }).describe('An S3 bucket that is used by the function.'),
}).describe('An S3 bucket that is used by the function.')
