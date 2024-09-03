import fs from 'node:fs/promises'
import path from 'node:path'
import { fromEntries, isRight, whenRight, whenRights } from '@skyleague/axioms'
import type { HTTPHandler, RequestAuthorizerEventHandler } from '@skyleague/event-horizon'
import { openapiFromHandlers } from '@skyleague/event-horizon/spec'
import type { Server } from '@skyleague/therefore/src/types/openapi.type.js'
import type { HttpTrigger } from '../definition/handler/events/http.type.js'
import type { StarchartConfiguration } from './configuration.js'

export async function openapi({ configuration, cwd }: { configuration: StarchartConfiguration; cwd?: string }) {
    const packageJson = JSON.parse((await fs.readFile(path.join(cwd ?? configuration.cwd, 'package.json'))).toString())

    return fromEntries(
        await Promise.all(
            configuration.stacks.map(async (stack) => {
                const stackHandlers = await Promise.all(
                    stack.handlers.map(async (h) => {
                        const symbol = await h.tryImport()
                        return 'left' in symbol
                            ? { left: symbol.left }
                            : {
                                  right: {
                                      configuration: h,
                                      symbol: symbol.right,
                                  },
                              }
                    }),
                )

                const handlerSecuritySchemes = whenRights(stackHandlers, (xs) => ({
                    right: xs
                        .filter((x) => x.configuration.handler.authorizer?.securityScheme !== undefined)
                        .map((x) => {
                            const authorizer = x.configuration.handler.authorizer
                            const securitySchemes =
                                authorizer !== undefined
                                    ? {
                                          [authorizer.name]: authorizer.securityScheme ?? {},
                                      }
                                    : undefined
                            const definition =
                                'request' in x.symbol
                                    ? (x.symbol.request as RequestAuthorizerEventHandler)
                                    : { security: undefined }
                            return {
                                ...definition.security,
                                ...securitySchemes,
                            }
                        }),
                }))

                const httpHandlers = whenRights(stackHandlers, (xs) => ({
                    right: xs
                        .filter((x) => 'http' in x.symbol)
                        .flatMap((x) => {
                            const definition = x.symbol.http as HTTPHandler
                            const httpEvents = x.configuration.handler.events?.filter(
                                (e): e is HttpTrigger => 'http' in e && e.http !== undefined,
                            )

                            return (
                                httpEvents?.map((e) => {
                                    const authorizer = e.http.authorizer
                                    return {
                                        configuration: x.configuration,
                                        handler: {
                                            ...e.http,
                                            http: {
                                                ...definition,
                                                ...e.http,
                                                security:
                                                    authorizer !== undefined
                                                        ? {
                                                              [authorizer.name]: authorizer.scopes ?? [],
                                                          }
                                                        : undefined,
                                            },
                                        },
                                    }
                                }) ?? []
                            )
                        }),
                }))

                const openapi = whenRight(httpHandlers, (xs) => {
                    const apigateway = stack.stack.httpApi ?? stack.stack.restApi
                    const securitySchemesComponent = isRight(handlerSecuritySchemes)
                        ? {
                              securitySchemes: {
                                  ...Object.assign({}, ...handlerSecuritySchemes.right),
                                  ...Object.fromEntries(
                                      Object.entries(apigateway?.authorizers ?? {})
                                          .filter(([_, authorizer]) => authorizer?.securityScheme !== undefined)
                                          .map(([name, authorizer]) => {
                                              return [name, authorizer?.securityScheme ?? {}]
                                          }),
                                  ),
                              },
                          }
                        : {}

                    const defaultAuthorizer = apigateway?.defaultAuthorizer
                    const openapi = openapiFromHandlers(
                        Object.fromEntries(
                            xs
                                .map((x, i) => [`${x.configuration.path}-${i}`, x.handler] as const)
                                .sort((a, z) => a[0].localeCompare(z[0])),
                        ),
                        {
                            info: {
                                title: `${configuration.starchart.project.name ?? packageJson.name} - ${stack.name}`,
                                version: packageJson.version,
                            },
                            servers: stack.stack.openapi?.servers as Server[],
                            security:
                                defaultAuthorizer !== undefined
                                    ? [
                                          {
                                              [defaultAuthorizer.name]: defaultAuthorizer.scopes ?? [],
                                          },
                                      ]
                                    : undefined,
                            components: {
                                ...securitySchemesComponent,
                            },
                        },
                    )
                    return { right: openapi }
                })

                if (!isRight(openapi)) {
                    throw new Error(`Failed to generate OpenAPI for stack ${stack.name}: ${JSON.stringify(openapi.left)}`)
                }

                return [stack.name, openapi.right]
            }),
        ),
    )
}
