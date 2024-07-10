import fs from 'node:fs/promises'
import path from 'node:path'
import { listLambdaHandlers } from '@skyleague/esbuild-lambda'
import camelcase from 'camelcase'
import { globby } from 'globby'
import yaml from 'js-yaml'
import type { Argv } from 'yargs'
import { StarChartHandler } from '../../definition/definition.type.js'
import { rootDirectory } from '../../lib/constants.js'
import { createWriter } from '../../lib/writer.js'

// biome-ignore lint/complexity/noBannedTypes: no args for now
export function builder(yargs: Argv): Argv<{}> {
    return yargs
}

export async function handler(_argv: ReturnType<typeof builder>['argv']): Promise<void> {
    const stacks = await globby(['src/**/functions'], { cwd: rootDirectory, onlyDirectories: true })
    const handlers = (
        await Promise.all(stacks.flatMap(async (fnDir) => listLambdaHandlers(path.join(rootDirectory, fnDir))))
    ).flat()

    await Promise.all(
        handlers.map(async (handler) => {
            const yamlHandler = `${handler}/handler.yml`
            if (!(await fs.stat(yamlHandler)).isFile()) {
                return
            }

            const content = await fs.readFile(yamlHandler)
            const handlerContent = yaml.load(content.toString())
            const eitherHandler = StarChartHandler.parse(handlerContent)
            if ('right' in eitherHandler) {
                console.log(`Handler ${handler} is valid`)
                const constants: Record<string, Record<string, string>> = {}

                for (const publishes of eitherHandler.right.publishes ?? []) {
                    if ('eventbridge' in publishes) {
                        constants.eventbridge ??= {}
                        constants.eventbridge[publishes.eventbridge.eventBusId] =
                            `STARCHART_EVENTBRIDGE_${publishes.eventbridge.eventBusId.replace(/[^a-zA-Z0-9]+/g, '_').toUpperCase()}`
                    } else if ('sqs' in publishes) {
                        constants.sqs ??= {}
                        constants.sqs[publishes.sqs.queueId] =
                            `STARCHART_SQS_${publishes.sqs.queueId.replace(/[^a-zA-Z0-9]+/g, '_').toUpperCase()}_QUEUE_URL`
                    }
                }

                for (const resource of eitherHandler.right.resources ?? []) {
                    if ('dynamodb' in resource) {
                        constants.dynamodb ??= {}
                        constants.dynamodb[resource.dynamodb.tableId] =
                            `STARCHART_${resource.dynamodb.tableId.replace(/[^a-zA-Z0-9]+/g, '_').toUpperCase()}_TABLE_NAME`
                    } else if ('s3' in resource) {
                        constants.s3 ??= {}
                        constants.s3[resource.s3.bucketId] =
                            `STARCHART_${resource.s3.bucketId.replace(/[^a-zA-Z0-9]+/g, '_').toUpperCase()}_BUCKET_NAME`
                    }

                    // @todo add secrets and parameters
                }

                const handlerName = path.basename(handler)

                const writer = createWriter()
                writer
                    .write(`export const ${camelcase(handlerName)} = `)
                    .inlineBlock(() => {
                        for (const [key, value] of Object.entries(constants)) {
                            writer
                                .write(`${key}: `)
                                .inlineBlock(() => {
                                    for (const [subKey, subValue] of Object.entries(value)) {
                                        writer.writeLine(`${subKey}: process.env.${subValue},`)
                                    }
                                })
                                .write(',\n')
                        }
                    })
                    .newLine()
                if (Object.keys(constants).length > 0) {
                    await fs.writeFile(`${handler}/lambda.env.ts`, writer.toString())
                }
            } else {
                console.error(`Handler ${handler} is invalid:`, eitherHandler.left)
            }
        }),
    )
}

export default {
    command: 'types',
    describe: 'Builds the lambda environment types',
    builder,
    handler,
}
