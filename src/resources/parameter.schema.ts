import { $enum, $object, $string, $union } from '@skyleague/therefore'

const parameterPath = $string().describe('The path to the SSM parameter.')

export const parameterResource = $object({
    parameter: $union([
        parameterPath,
        $object({
            path: parameterPath,
            actions: $enum(['read']).array({ minItems: 1 }),
        }).describe('An SSM parameter that is used by the function.'),
    ]),
}).describe('An SSM parameter that is used by the function.')
