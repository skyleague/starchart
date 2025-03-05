import { $object, $string } from '@skyleague/therefore'

export const fooData = $object({
    message: $string(),
}).validator()
