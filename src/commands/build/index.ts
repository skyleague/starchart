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
}

export async function handler(argv: ReturnType<typeof builder>['argv']): Promise<void> {
    const { buildDir: _buildDir, artifactDir: _artifactDir } = await argv
    const buildDir = path.join(rootDirectory, _buildDir)
    const artifactDir = path.join(rootDirectory, _artifactDir)

    await fs.promises.rm(artifactDir, { recursive: true }).catch(() => void {})
    await fs.promises.mkdir(artifactDir)

    const stacks = await globby(['src/**/functions'], { cwd: rootDirectory, onlyDirectories: true })
    const handlers = (
        await Promise.all(stacks.flatMap(async (fnDir) => listLambdaHandlers(path.join(rootDirectory, fnDir))))
    ).flat()

    const outbase = path.join(rootDirectory, 'src')

    await esbuildLambda(rootDirectory, {
        esbuild: {
            absWorkingDir: rootDirectory,
            tsconfig: path.join(rootDirectory, 'tsconfig.dist.json'),
            outbase,
        },
        root: rootDirectory,
        entryPoints: handlers.map((fnDir) => path.join(fnDir, 'index.ts')),
        outdir: () => buildDir,
        forceBundle: () => true,
    })

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
