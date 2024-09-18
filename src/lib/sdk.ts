import type { RestClientOptions } from '@skyleague/therefore/src/lib/primitives/restclient/restclient.js'
import { StarchartConfiguration } from './configuration.js'
import { openapi } from './openapi.js'

export async function $sdk(options: Record<string, Partial<RestClientOptions> | undefined> = {}) {
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
                const clientOptions = options[key] ?? options._default ?? options.default
                return [
                    `${key}Client`,
                    $restclient(value, {
                        ...clientOptions,
                        filename: `${key}/rest.client.ts`,
                    }),
                ]
            }),
    )
}
