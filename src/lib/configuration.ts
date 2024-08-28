import fs from 'node:fs/promises'
import nodePath from 'node:path'
import { isFailure, mapTry } from '@skyleague/axioms'
import type { Schema } from '@skyleague/therefore'
import betterAjvErrors from 'better-ajv-errors'
import { globby } from 'globby'
import yaml from 'yaml'
import { StarChartHandler } from '../definition/handler.type.js'
import { Stack } from '../definition/stack.type.js'
import { Starchart } from '../definition/starchart.type.js'
import { rootDirectory } from './constants.js'

export function validationError({
    schema,
    data,
    filename,
}: { schema: Schema<unknown>; data: unknown; filename: string }): string {
    return `Found an error in file ${filename}:\n\n${betterAjvErrors(schema.schema, data, schema.errors, { indent: 2 })}`
}

export class HandlerConfiguration {
    handler: StarChartHandler
    path: string
    constructor({ handler, path }: { handler: StarChartHandler; path: string }) {
        this.handler = handler
        this.path = path
    }

    public static async load({ path }: { path: string; stack: StackConfiguration }) {
        if (await fs.stat(path).then((s) => s.isFile())) {
            const content = await mapTry(path, (t) => fs.readFile(t))
            const handler = mapTry(content, (c) => yaml.parse(c.toString()))

            if (isFailure(handler)) {
                return { left: handler }
            }

            const handlerConfiguration = StarChartHandler.parse(handler)
            if ('left' in handlerConfiguration) {
                return { left: validationError({ schema: StarChartHandler, data: handler, filename: path }) }
            }
            return { right: new HandlerConfiguration({ handler: handlerConfiguration.right, path }) }
        }
        return { left: new Error('Could not find handler.yml') }
    }

    public async tryImport() {
        // biome-ignore lint/style/noNonNullAssertion: this is the format we require
        const [filePart, symbolName] = this.handler.handler!.split('.')
        const handlerFile = nodePath.join(nodePath.dirname(this.path), `${filePart}.ts`)
        if (!(await fs.stat(handlerFile)).isFile()) {
            return { left: 'Handler file not found' }
        }
        // biome-ignore lint/style/noNonNullAssertion: symbol should be defineds
        return { right: (await import(handlerFile))[symbolName!] }
    }
}

export class StackConfiguration {
    stack: Stack
    handlers: HandlerConfiguration[]
    name: string
    target: string
    constructor({ stack, name, target }: { stack: Stack; name: string; target: string }) {
        this.stack = stack
        this.handlers = []
        this.name = name
        this.target = target
    }

    public static async load({ directory, name }: { directory: string; name: string }) {
        const target = nodePath.join(directory, 'stack.yml')
        if (await fs.stat(target).then((s) => s.isFile())) {
            const content = await mapTry(target, (t) => fs.readFile(t))
            const stack = mapTry(content, (c) => yaml.parse(c.toString()))

            if (isFailure(stack)) {
                return { left: stack }
            }

            const stackConfiguration = Stack.parse(stack)
            if ('left' in stackConfiguration) {
                return { left: validationError({ schema: Stack, data: stack, filename: target }) }
            }
            const loadedStack = new StackConfiguration({ stack: stackConfiguration.right, name, target })
            // biome-ignore lint/style/noNonNullAssertion:
            const handlers = await globby(`**/${stackConfiguration.right.lambda!.handlerFile!}`, {
                cwd: directory,
            })

            for (const handler of handlers) {
                const handlerConfiguration = await HandlerConfiguration.load({
                    path: nodePath.join(directory, handler),
                    stack: loadedStack,
                })
                if ('left' in handlerConfiguration) {
                    return { left: handlerConfiguration.left }
                }
                loadedStack.handlers.push(handlerConfiguration.right)
            }

            return { right: loadedStack }
        }
        return { left: new Error('Could not find stack.yml') }
    }
}

export class StarchartConfiguration {
    starchart: Starchart
    stacks: StackConfiguration[]
    target: string
    cwd: string
    constructor({
        starchart,
        stacks,
        target,
        cwd,
    }: { starchart: Starchart; stacks: StackConfiguration[]; target: string; cwd: string }) {
        this.starchart = starchart
        this.stacks = stacks
        this.target = target
        this.cwd = cwd
    }

    public static async load({ cwd = rootDirectory }: { cwd?: string } = {}) {
        const target = nodePath.join(cwd, 'starchart.yml')
        if (await fs.stat(target).then((s) => s.isFile())) {
            const content = await mapTry(target, (t) => fs.readFile(t))
            const starchart = mapTry(content, (c) => yaml.parse(c.toString()))

            if (isFailure(starchart)) {
                return { left: starchart }
            }

            const starchartConfiguration = Starchart.parse(starchart)
            if ('left' in starchartConfiguration) {
                return { left: validationError({ schema: Starchart, data: starchart, filename: target }) }
            }

            const stacks: StackConfiguration[] = []
            for (const [name, stack] of Object.entries(starchartConfiguration.right.stacks)) {
                if (stack === undefined) {
                    continue
                }
                const stackConfiguration = await StackConfiguration.load({ name, directory: nodePath.join(cwd, stack.path) })
                if ('left' in stackConfiguration) {
                    return { left: stackConfiguration.left }
                }
                stacks.push(stackConfiguration.right)
            }

            return { right: new StarchartConfiguration({ starchart: starchartConfiguration.right, stacks, target, cwd }) }
        }

        return { left: new Error('Could not find starchart.yml') }
    }
}
