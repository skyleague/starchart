/**
 * Generated by @skyleague/therefore@v1.0.0-local
 * Do not manually touch this
 */
/* eslint-disable */

import type { Monitoring } from './monitoring/apigateway.type.js'
import StarchartSchema from './schemas/starchart.schema.json' with { type: 'json' }

import { Ajv } from 'ajv'
import type { DefinedError } from 'ajv'

export interface Starchart {
    project: {
        /**
         * The name of the project.
         */
        name: string
        /**
         * The identifier of the project.
         */
        identifier: string
    }
    /**
     * The parameters to be used when rendering the handler definition.
     */
    params?:
        | {
              [k: string]:
                  | {
                        [k: string]: string | undefined
                    }
                  | undefined
          }
        | undefined
    monitoring?: Monitoring | undefined
    /**
     * The stacks to deploy.
     */
    stacks: {
        [k: string]:
            | {
                  /**
                   * The path to the stack.
                   */
                  path: string
              }
            | undefined
    }
}

export const Starchart = {
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
    }).compile<Starchart>(StarchartSchema),
    schema: StarchartSchema,
    get errors() {
        return Starchart.validate.errors ?? undefined
    },
    is: (o: unknown): o is Starchart => Starchart.validate(o) === true,
    parse: (o: unknown): { right: Starchart } | { left: DefinedError[] } => {
        if (Starchart.is(o)) {
            return { right: o }
        }
        return { left: (Starchart.errors ?? []) as DefinedError[] }
    },
} as const
