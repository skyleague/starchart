import fs from 'node:fs'
import path from 'node:path'
import { esbuildLambda, listLambdaHandlers, zipHandlers } from '@skyleague/esbuild-lambda'
import type { Argv } from 'yargs'
import { StarchartConfiguration } from '../../lib/configuration.js'
import { rootDirectory } from '../../lib/constants.js'

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

    const stacks = configuration.right?.stacks.map((s) => path.dirname(s.target)) ?? []

    const handlers = (
        await Promise.all(
            [
                ...(options.stacks ?? []),
                ...stacks.filter((handler) => targetedStacks.includes('*') || targetedStacks.some((t) => handler.includes(t))),
            ].flatMap(async (fnDir) => listLambdaHandlers(fnDir)),
        )
    ).flat()

    const outbase = rootDirectory

    await esbuildLambda(rootDirectory, {
        esbuild: {
            absWorkingDir: rootDirectory,
            tsconfig: path.join(rootDirectory, 'tsconfig.dist.json'),
            outbase: rootDirectory,
        },
        root: rootDirectory,
        modulesRoot: rootDirectory,
        entryPoints: handlers.map((fnDir) => path.join(fnDir, 'index.ts')),
        outdir: () => buildDir,
        forceBundle: ({ packageName }) => packageName !== 'aws-crt',
    })

    await postBuild?.()

    await zipHandlers(handlers, {
        outbase,
        buildDir,
        artifactDir,
    })
}

export default {
    command: 'build',
    describe: 'Builds the lambda handlers',
    builder,
    handler,
}
