/**
 * Generated by @skyleague/therefore@v1.0.0-local
 * Do not manually touch this
 */
/* eslint-disable */

import type { SecurityScheme, Servers } from './openapi.type.js'
import StackSchema from './schemas/stack.schema.json' with { type: 'json' }

import { Ajv } from 'ajv'
import type { DefinedError } from 'ajv'

export interface Apigateway {
    /**
     * The name of the API Gateway, defaults to the stack name.
     */
    name?: string | undefined
    /**
     * Defer deployment of the API to a later stage.
     *
     * @default false
     */
    deferDeployment?: boolean | undefined
    /**
     * Disable the execute-api endpoint.
     *
     * @default true
     */
    disableExecuteApiEndpoint?: boolean | undefined
    /**
     * Map of authorizers for the API.
     *
     * @default {  }
     */
    authorizers?:
        | {
              [k: string]: (HttpApiRequestAuthorizer | JwtAuthorizer) | undefined
          }
        | undefined
    /**
     * The default authorizer for the API.
     */
    defaultAuthorizer?:
        | {
              /**
               * The default authorizer for the API.
               */
              name: string
              /**
               * The default scopes for the API.
               */
              scopes?: string[] | undefined
          }
        | undefined
}

export type HttpApiRequestAuthorizer = RequestAuthorizer & {
    /**
     * Enable simple responses for the authorizer.
     *
     * @default true
     */
    enableSimpleResponses?: boolean | undefined
    /**
     * The payload format version for the authorizer.
     *
     * @default '2.0'
     */
    payloadFormatVersion?: string | undefined
}

export type JwtAuthorizer = {
    /**
     * The type of the authorizer.
     */
    type: 'jwt'
    /**
     * The identity source for the authorizer.
     */
    identitySource?: string | undefined
    /**
     * The TTL for the authorizer.
     *
     * @default 60
     */
    ttlInSeconds?: number | undefined
    /**
     * The issuer for the authorizer.
     */
    issuer: string
    /**
     * The audience for the authorizer.
     */
    audience: string[]
    /**
     * The security requirements to use for the route.
     */
    securityScheme?: SecurityScheme | undefined
}

export type RequestAuthorizer = {
    /**
     * The type of the authorizer.
     */
    type: 'request'
    /**
     * The TTL for the authorizer.
     *
     * @default 60
     */
    ttlInSeconds?: number | undefined
    /**
     * The identity source for the authorizer.
     */
    identitySource?: string[] | undefined
    /**
     * The security requirements to use for the route.
     */
    securityScheme?: SecurityScheme | undefined
} & (
    | {
          /**
           * The function ID for the authorizer.
           */
          functionId?: string | undefined
      }
    | {
          /**
           * The function arn for the authorizer.
           */
          functionName?: string | undefined
      }
)

export interface Stack {
    httpApi?: Apigateway | undefined
    restApi?: Apigateway | undefined
    /**
     * The configuration for the lambda runtime.
     *
     * @default {  }
     */
    lambda?:
        | {
              runtime?: 'nodejs18.x' | 'nodejs20.x' | 'python3.8' | 'python3.9' | 'python3.10' | undefined
              memorySize?: number | undefined
              timeout?: number | undefined
              /**
               * The name of the handler function to invoke.
               *
               * @default 'index.handler'
               */
              handler?: string | undefined
              vpcConfig?: string | undefined
              /**
               * The environment variables to set for the handler.
               */
              environment?:
                  | {
                        [k: string]: string | undefined
                    }
                  | undefined
              inlinePolicies?: unknown[] | undefined
              /**
               * The directory containing the functions to be deployed.
               */
              functionsDir?: string | undefined
              /**
               * The prefix to be used when naming the functions.
               */
              functionPrefix?: string | undefined
              /**
               * The name of the file containing the handler definition.
               *
               * @default 'handler.yml'
               */
              handlerFile?: string | undefined
          }
        | undefined
    /**
     * The configuration for the OpenAPI.
     */
    openapi?:
        | {
              servers?: Servers | undefined
          }
        | undefined
}

export const Stack = {
    validate: new Ajv({
        strict: true,
        strictSchema: false,
        strictTypes: true,
        strictTuples: false,
        useDefaults: true,
        logger: false,
        loopRequired: 5,
        loopEnum: 5,
        multipleOfPrecision: 4,
        code: { esm: true },
    }).compile<Stack>(StackSchema),
    schema: StackSchema,
    get errors() {
        return Stack.validate.errors ?? undefined
    },
    is: (o: unknown): o is Stack => Stack.validate(o) === true,
    parse: (o: unknown): { right: Stack } | { left: DefinedError[] } => {
        if (Stack.is(o)) {
            return { right: o }
        }
        return { left: (Stack.errors ?? []) as DefinedError[] }
    },
} as const
