import { StarchartConfiguration } from './configuration.js'
import { openapi } from './openapi.js'

export async function $sdk() {
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
                return [
                    `${key}Client`,
                    $restclient(value, {
                        filename: `${key}/rest.client.ts`,
                    }),
                ]
            }),
    )
}
