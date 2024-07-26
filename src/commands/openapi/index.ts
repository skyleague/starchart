import fs from 'node:fs/promises'
import path from 'node:path'
import { listLambdaHandlers } from '@skyleague/esbuild-lambda'
import { openapiFromHandlers } from '@skyleague/event-horizon/spec'
import { globby } from 'globby'
import type { Argv } from 'yargs'
import { rootDirectory } from '../../lib/constants.js'

export function builder(yargs: Argv) {
    return yargs
        .option('output', {
            type: 'string',
        })
        .option('cwd', {
            type: 'string',
            default: rootDirectory,
            coerce: (cwd) => path.join(process.cwd(), cwd),
        })
}

export async function handler(argv: ReturnType<typeof builder>['argv']): Promise<void> {
    const { buildDir: _buildDir, artifactDir: _artifactDir, output, cwd } = await argv
    const fnDirs = ['src/**/functions']

    const stacks = await globby(fnDirs, { cwd: cwd, onlyDirectories: true })
    const handlers = (await Promise.all(stacks.flatMap(async (fnDir) => listLambdaHandlers(path.join(cwd, fnDir)))))
        .flat()
        .map((handler) => path.join(handler, 'index.ts'))

    const packageJson = JSON.parse((await fs.readFile(path.join(cwd, 'package.json'))).toString())

    const openapi = openapiFromHandlers(
        Object.fromEntries(await Promise.all(handlers.map(async (handler) => [handler, (await import(handler)).handler]))),
        { info: { title: packageJson.name, version: packageJson.version } },
    )

    const content = JSON.stringify(openapi, null, 2)
    if (output !== undefined) {
        await fs.writeFile(output, content)
    } else {
        console.log(content)
    }
}

export default {
    command: 'openapi',
    describe: 'Build OpenAPI',
    builder,
    handler,
}
