import { tsImport } from 'tsx/esm/api'

process.on('message', async ({ lambdaFn, event, context, rootDirectory }) => {
    let handler: ((...args: unknown[]) => unknown) | undefined = undefined
    try {
        const loaded = await tsImport(`.${lambdaFn.tags.Path}.ts`, `${rootDirectory}/`)
        if ('handler' in loaded && typeof loaded.handler === 'function') {
            handler = loaded.handler
        }
    } catch (error) {
        console.error(`Error loading handler for ${lambdaFn.tags.Path}`)
        process.send?.({ left: (error as { message: string }).message })
        return
    }

    if (handler !== undefined && context !== undefined) {
        const response = await handler(event, { ...context, getRemainingTimeInMillis: () => 1000 })
        process.send?.({ right: response })
    } else {
        process.send?.({ left: 'Handler function not found or context is undefined' })
    }
})
