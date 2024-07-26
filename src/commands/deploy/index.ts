import { spawnSync } from 'node:child_process'
import path from 'node:path'
import { globby } from 'globby'
import type { Argv } from 'yargs'
import { StarchartConfiguration } from '../../lib/configuration.js'
import { type BuildOptions, builder as buildBuilder, handler as buildHandler } from '../build/index.js'

export function builder(yargs: Argv) {
    return buildBuilder(yargs)
        .option('refresh', {
            describe: 'refresh the state before applying',
            type: 'boolean',
            default: true,
        })
        .option('cwd', {
            type: 'string',
            default: '.',
            example: 'terraform/dev',
            demandOption: true,
            coerce: (cwd) => path.join(process.cwd(), cwd),
        })
}

export interface DeployOptions extends BuildOptions {}

export async function handler(argv: ReturnType<typeof builder>['argv'], options: DeployOptions = {}): Promise<void> {
    const { cwd, refresh, stack } = await argv
    const { configuration: _configuration } = options

    const configuration = _configuration !== undefined ? { right: _configuration } : await StarchartConfiguration.load({})
    if ('left' in configuration) {
        console.error(configuration.left)
        return
    }

    const stacks = stack.flatMap((t) => t.split(','))

    const [foundStacks] = await Promise.all([
        globby(['**/*.hcl'], { cwd: cwd, onlyDirectories: false }),
        buildHandler(argv, { ...options, configuration: configuration.right }),
    ])

    const groups = foundStacks
        .map((s) => path.join(cwd, path.dirname(s)))
        .filter((stack) => stacks.includes('*') || stacks.some((t) => stack.includes(t)))

    console.log('Deploying stacks')

    spawnSync(
        'terragrunt',
        [
            '--terragrunt-non-interactive',
            ...(stacks.includes('*')
                ? ['run-all', 'apply']
                : ['run-all', 'apply', '--terragrunt-strict-include', ...groups.flatMap((t) => ['--terragrunt-include-dir', t])]),
            ...(refresh === false ? ['-refresh=false'] : []),
            '--terragrunt-fetch-dependency-output-from-state',
        ],
        {
            stdio: 'inherit',
            cwd,
        },
    )
}

export default {
    command: 'deploy',
    describe: 'deploy the given stacks',
    builder,
    handler,
}
