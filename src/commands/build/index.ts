import fs from 'node:fs'
import path from 'node:path'
import { esbuildLambda, listLambdaHandlers, zipHandlers } from '@skyleague/esbuild-lambda'
import { globby } from 'globby'
import type { Argv } from 'yargs'
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
        .option('target', {
            type: 'array',
            default: ['*'],
            string: true,
        })
        .option('clean', {
            type: 'boolean',
            default: true,
        })
        .option('dot', {
            type: 'boolean',
            default: false,
        })
}

export type BuildOptions = {
    fnDirs?: string[]
    stacks?: string[]
    preBuild?: () => Promise<void> | void
    postBuild?: () => Promise<void> | void
}

export async function handler(argv: ReturnType<typeof builder>['argv'], options: BuildOptions = {}): Promise<void> {
    const { buildDir: _buildDir, artifactDir: _artifactDir, target, clean, dot } = await argv
    const { fnDirs = ['src/**/functions'], preBuild, postBuild } = options
    const buildDir = path.join(rootDirectory, _buildDir)
    const artifactDir = path.join(rootDirectory, _artifactDir)

    const targets = target.flatMap((t) => t.split(','))

    if (clean) {
        if (targets.includes('*')) {
            fs.rmSync(artifactDir, { recursive: true, force: true })
        }
        fs.rmSync(buildDir, { recursive: true, force: true })
    }
    fs.mkdirSync(artifactDir, { recursive: true })

    await preBuild?.()

    const stacks = await globby(fnDirs, { cwd: rootDirectory, onlyDirectories: true, dot })
    const handlers = (
        await Promise.all(
            [
                ...(options.stacks ?? []),
                ...stacks.filter((handler) => targets.includes('*') || targets.some((t) => handler.includes(t))),
            ].flatMap(async (fnDir) => listLambdaHandlers(path.join(rootDirectory, fnDir))),
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
