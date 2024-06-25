import { $enum, $object, $string, $union } from '@skyleague/therefore'

const secretPath = $string().describe('The path to the secret.')

export const secretResource = $object({
    secret: $union([
        secretPath,
        $object({
            path: secretPath,
            actions: $enum(['read', 'rotation']).array({ minItems: 1 }),
        }).describe('A secret that is used by the function.'),
    ]),
}).describe('A secret that is used by the function.')
