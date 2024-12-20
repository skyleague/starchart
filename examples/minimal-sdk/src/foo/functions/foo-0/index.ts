import { httpApiHandler } from '@skyleague/event-horizon'
import { FooResponse } from './foo-0.type.js'

export const handler = httpApiHandler({
    http: {
        method: 'get',
        path: '/foo',
        schema: {
            responses: {
                200: {
                    body: FooResponse,
                },
            },
        },
        handler: (_event, _context) => {
            return {
                statusCode: 200,
                body: {
                    data: {
                        message: 'Hello World!',
                    },
                },
            }
        },
    },
})
