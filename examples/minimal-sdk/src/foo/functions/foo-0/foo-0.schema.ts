import { $object, $ref } from '@skyleague/therefore'
import { fooData } from '../../lib/response.schema.js'

export const fooResponse = $object({
    data: $ref(fooData),
}).validator()
