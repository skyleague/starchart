import crypto from 'node:crypto'
import fs from 'node:fs'
import path from 'node:path'
import { fileURLToPath } from 'node:url'
import { IAM } from '@aws-sdk/client-iam'
import { type FunctionConfiguration, Lambda, paginateListFunctions } from '@aws-sdk/client-lambda'
import {} from '@skyleague/esbuild-lambda'
import type { Argv } from 'yargs'
import { rootDirectory } from '../../lib/constants.js'
import { handler as buildHandler } from '../build/index.js'
import { builder as deployBuilder, handler as deployHandler } from '../deploy/index.js'
import { type LambdaFunction, patchDebugFunction } from './function.js'
import { local } from './local.js'

const __dirname = path.dirname(fileURLToPath(import.meta.url))

function sha256Hash(data: Uint8Array) {
    const hash = crypto.createHash('sha256')
    hash.update(data)
    return hash.digest('base64')
}

export function builder(yargs: Argv) {
    return deployBuilder(yargs)
        .option('stack', {
            type: 'array',
            default: ['*'],
            string: true,
        })
        .option('dir', {
            describe: 'environment directory',
            type: 'string',
            default: '.',
            example: 'terraform/dev',
            demandOption: true,
        })
        .option('refresh', {
            describe: 'refresh the state before applying',
            type: 'boolean',
            default: true,
        })
        .option('deploy', {
            describe: 'refresh the stacks before starting debug',
            type: 'boolean',
            default: false,
        })
}

export async function handler(argv: ReturnType<typeof builder>['argv']): Promise<void> {
    const options = await argv
    const { deploy, buildDir: _buildDir, artifactDir: _artifactDir, stack } = options
    const artifactDir = path.join(rootDirectory, _artifactDir)

    const stacks = stack.flatMap((t) => t.split(','))

    const debugPath = '.debug'
    const debugDir = path.join(_buildDir, debugPath)
    const debugArtifact = path.join(artifactDir, _buildDir, `${debugPath}.zip`)

    const debugLambda = path.join(path.join(rootDirectory, debugDir), 'index.ts')

    const hasDebugArtifact = fs.existsSync(debugArtifact) && false

    const remoteLambda = fs.existsSync(`${__dirname}/lambda.ts`)
        ? fs.readFileSync(`${__dirname}/lambda.ts`).toString()
        : fs.existsSync(`${__dirname}/lambda.js`)
          ? fs.readFileSync(`${__dirname}/lambda.js`).toString()
          : undefined
    const remoteLambdaContent = [remoteLambda, ' export const handler = proxyHandler()'].join('\n')

    if (remoteLambda === undefined) {
        throw new Error('No remote lambda contents found, please provide a lambda.ts or lambda.js file')
    }

    const buildRemoteLambdaArtifact =
        !hasDebugArtifact || (fs.existsSync(debugLambda) && fs.readFileSync(debugLambda).toString() !== remoteLambdaContent)

    const preBuild = () => {
        fs.mkdirSync(path.join(rootDirectory, debugDir), { recursive: true })

        fs.writeFileSync(debugLambda, remoteLambdaContent)
    }

    if (deploy) {
        await deployHandler(
            { ...options, clean: false },
            {
                stacks: buildRemoteLambdaArtifact ? [debugDir] : [],
                preBuild,
            },
        )
    } else {
        await buildHandler(
            { ...options, fnDir: [], clean: false },
            {
                fnDirs: [],
                stacks: !hasDebugArtifact ? [debugDir] : [],
                preBuild,
            },
        )
    }
    const lambda = new Lambda({
        region: 'eu-west-1',
    })

    const iam = new IAM({
        region: 'eu-west-1',
    })

    const paginator = paginateListFunctions({ client: lambda, pageSize: 10 }, {})

    const configurations: FunctionConfiguration[] = []

    for await (const page of paginator) {
        // only keep funtions that start with the any of the given stacks
        configurations.push(...(page.Functions?.filter((f) => stacks.some((s) => f.FunctionName?.startsWith(s))) ?? []))
    }

    const functions: LambdaFunction[] = (
        await Promise.all(
            configurations.map(async (f) => ({
                configuration: f,
                tags: (await lambda.listTags({ Resource: f.FunctionArn })).Tags ?? {},
            })),
        )
    ).filter((f) => f.tags.Stack !== undefined && stack.includes(f.tags.Stack))

    const zipFile = new Uint8Array(fs.readFileSync(debugArtifact).buffer)
    const codeSha256 = sha256Hash(zipFile)
    await Promise.all(functions.map((f) => patchDebugFunction({ fn: f, lambda, debugZip: zipFile, iam, codeSha256 })))

    await local(functions)
}

export default {
    command: 'dev',
    describe: 'starts a dev deploy',
    builder,
    handler,
}
