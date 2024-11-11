import fs from 'node:fs'
import path from 'node:path'
import { entriesOf, groupBy } from '@skyleague/axioms'
import { esbuildLambda, zipHandlers } from '@skyleague/esbuild-lambda'
import type { Argv } from 'yargs'
import { StarchartConfiguration } from '../../lib/configuration.js'
import { rootDirectory } from '../../lib/constants.js'
import { buildPython } from './python.js'

export function builder(yargs: Argv) {
    return yargs
        .option('buildDir', {
            describe: 'directory to build lambdas to',
            type: 'string',
            default: '.build',
        })
        .option('artifactDir', {
            describe: 'directory to store artifacts',
            type: 'string',
            default: '.artifacts',
        })
        .option('stack', {
            type: 'array',
            default: ['*'],
            string: true,
        })
        .option('clean', {
            type: 'boolean',
            default: true,
        })
}

export type BuildOptions = {
    fnDirs?: string[]
    stacks?: string[]
    preBuild?: () => Promise<void> | void
    postBuild?: () => Promise<void> | void
    configuration?: StarchartConfiguration
}

export async function handler(argv: ReturnType<typeof builder>['argv'], options: BuildOptions = {}): Promise<void> {
    const { buildDir: _buildDir, artifactDir: _artifactDir, stack, clean } = await argv
    const { preBuild, postBuild, configuration: _configuration } = options
    const buildDir = path.join(rootDirectory, _buildDir)
    const artifactDir = path.join(rootDirectory, _artifactDir)

    const configuration = _configuration !== undefined ? { right: _configuration } : await StarchartConfiguration.load()
    if ('left' in configuration) {
        console.error(configuration.left)
        return
    }

    const targetedStacks = stack.flatMap((t) => t.split(','))

    if (clean) {
        if (targetedStacks.includes('*')) {
            fs.rmSync(artifactDir, { recursive: true, force: true })
        }
        fs.rmSync(buildDir, { recursive: true, force: true })
    }
    fs.mkdirSync(artifactDir, { recursive: true })

    await preBuild?.()

    const allHandlers = configuration.right.stacks.flatMap((s) => s.handlers)
    const groupedHandlers = groupBy(allHandlers, (h) => h.type())

    const outbase = rootDirectory

    if (groupedHandlers.nodejs) {
        await esbuildLambda(rootDirectory, {
            esbuild: {
                absWorkingDir: rootDirectory,
                tsconfig: path.join(rootDirectory, 'tsconfig.dist.json'),
                outbase: rootDirectory,
            },
            root: rootDirectory,
            modulesRoot: rootDirectory,
            entryPoints: groupedHandlers.nodejs.map((h) => h.endpoint),
            outdir: () => buildDir,
            forceBundle: ({ packageName }) => packageName !== 'aws-crt',
        })
    }

    if (groupedHandlers.python) {
        await buildPython(groupedHandlers, buildDir)
    }

    await postBuild?.()

    await Promise.all(
        entriesOf(groupBy(allHandlers, (h) => h.handler.runtime ?? 'nodejs')).map(async ([runtime, handlers]) => {
            await zipHandlers(
                handlers.map((h) => h.zipSource()),
                {
                    outbase,
                    buildDir,
                    artifactDir,
                    runtime: runtime as 'nodejs20.x',
                },
            )
        }),
    )
}

export default {
    command: 'build',
    describe: 'Builds the lambda handlers',
    builder,
    handler,
}
