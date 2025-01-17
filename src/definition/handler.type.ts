/**
 * Generated by @skyleague/therefore@v1.0.0-local
 * Do not manually touch this
 */
/* eslint-disable */

import type { Events } from './handler/events/index.type.js'
import type { Publishes } from './handler/publishes/index.type.js'
import type { Resources } from './handler/resources/index.type.js'
import type { SecurityScheme } from './openapi.type.js'
import StarChartHandlerSchema from './schemas/star-chart-handler.schema.json' with { type: 'json' }

import { Ajv } from 'ajv'
import type { DefinedError } from 'ajv'

/**
 * The definition of a Star Chart handler.
 */
export interface StarChartHandler {
    /**
     * The name of the handler function to invoke.
     */
    handler?: string | undefined
    /**
     * The ID of the function. Defaults to the name of the folder.
     */
    functionId?: string | undefined
    /**
     * The name of the function. Defaults to the function ID.
     */
    functionName?: string | undefined
    /**
     * The environment variables to set for the handler.
     */
    environment?:
        | {
              [k: string]: string | undefined
          }
        | undefined
    /**
     * The warmer to use to keep the handler warm. Defaults to enabled, rate: 10 minutes.
     */
    warmer?:
        | {
              /**
               * The name to give the scheduled rule. Defaults to prefixing the name of the handler.
               */
              ruleName?: string | undefined
              /**
               * The prefix to give the scheduled rule. Defaults to the name of the handler.
               */
              ruleNamePrefix?: string | undefined
              /**
               * The description to give the scheduled rule.
               */
              description?: string | undefined
              /**
               * The rate at which to invoke the handler. Must be a valid rate expression. See https://docs.aws.amazon.com/AmazonCloudWatch/latest/events/ScheduledEvents.html for more information.
               */
              rate?: string | undefined
              /**
               * Whether the rule should be enabled. Defaults to true.
               */
              enabled?: boolean | undefined
              /**
               * The input to pass to the handler. Defaults to an empty object. Conflicts with inputPath and inputTransformer
               */
              input?: unknown
              /**
               * The JSONPath to use to extract the input to pass to the handler. Conflicts with input and inputTransformer.
               */
              inputPath?: string | undefined
              /**
               * The input transformer to use to transform the input to pass to the handler. Conflicts with input and inputPath. See https://docs.aws.amazon.com/eventbridge/latest/userguide/eb-transform-target-input.html for more information.
               */
              inputTransformer?:
                  | {
                        /**
                         * The JSONPaths to use to extract the input to pass to the handler.
                         */
                        inputPaths?:
                            | {
                                  [k: string]: string | undefined
                              }
                            | undefined
                        /**
                         * The template to use to transform the input to pass to the handler.
                         */
                        inputTemplate: string
                    }
                  | undefined
          }
        | undefined
    events?: Events | undefined
    publishes?: Publishes | undefined
    resources?: Resources | undefined
    inlinePolicies?:
        | (
              | {
                    [k: string]: unknown
                }
              | string
          )[]
        | undefined
    runtime?: 'nodejs18.x' | 'nodejs20.x' | 'nodejs22.x' | 'python3.8' | 'python3.9' | 'python3.10' | undefined
    memorySize?: number | undefined
    timeout?: number | undefined
    vpcConfig?: string | undefined
    /**
     * Define that this lambda defines an authorizer.
     */
    authorizer?:
        | {
              /**
               * The name of the authorizer to use for the route.
               */
              name: string
              /**
               * The security schemes to use for the route.
               */
              securityScheme?: SecurityScheme | undefined
          }
        | undefined
}

export const StarChartHandler = {
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
    }).compile<StarChartHandler>(StarChartHandlerSchema),
    schema: StarChartHandlerSchema,
    get errors() {
        return StarChartHandler.validate.errors ?? undefined
    },
    is: (o: unknown): o is StarChartHandler => StarChartHandler.validate(o) === true,
    parse: (o: unknown): { right: StarChartHandler } | { left: DefinedError[] } => {
        if (StarChartHandler.is(o)) {
            return { right: o }
        }
        return { left: (StarChartHandler.errors ?? []) as DefinedError[] }
    },
} as const
