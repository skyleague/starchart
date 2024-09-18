import type { RestClientOptions } from '@skyleague/therefore/src/lib/primitives/restclient/restclient.js'
import { StarchartConfiguration } from './configuration.js'
import { openapi } from './openapi.js'

export async function $sdk(
    options: Record<
        string,
        Partial<RestClientOptions> | ((args: { key: string }) => Partial<RestClientOptions>) | undefined
    > = {},
) {
    const { $restclient } = await import('@skyleague/therefore')
    const configuration = await StarchartConfiguration.load({})
    if ('left' in configuration) {
        console.error(configuration.left)
        return
    }
    const openapiDocs = await openapi({ configuration: configuration.right })

    return Object.fromEntries(
        Object.entries(openapiDocs)
            .filter(([, value]) => Object.keys(value.paths).length > 0)
            .map(([key, value]) => {
                let clientOptions = options[key] ?? options._default ?? options.default
                if (typeof clientOptions === 'function') {
                    clientOptions = clientOptions({ key })
                }

                return [
                    `${key}Client`,
                    $restclient(value, {
                        filename: `${key}/rest.client.ts`,
                        ...clientOptions,
                    }),
                ]
            }),
    )
}
