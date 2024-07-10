import { spawnSync } from 'node:child_process'
import path from 'node:path'
import { globby } from 'globby'
import type { Argv } from 'yargs'
import { builder as buildBuilder, handler as buildHandler } from '../build/index.js'

export function builder(yargs: Argv) {
    return buildBuilder(yargs)
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
}

export async function handler(argv: ReturnType<typeof builder>['argv']): Promise<void> {
    const { target, dir, refresh } = await argv
    const targets = target.flatMap((t) => t.split(','))
    const cwd = path.join(process.cwd(), dir)

    const [stacks] = await Promise.all([globby(['**/*.hcl'], { cwd: cwd, onlyDirectories: false }), buildHandler(argv)])

    const groups = stacks
        .map((s) => path.join(cwd, path.dirname(s)))
        .filter((stack) => targets.includes('*') || targets.some((t) => stack.includes(t)))

    console.log('Deploying stacks')

    spawnSync(
        'terragrunt',
        [
            '--terragrunt-non-interactive',
            ...(targets.includes('*')
                ? ['run-all', 'apply']
                : ['run-all', 'apply', '--terragrunt-strict-include', ...groups.flatMap((t) => ['--terragrunt-include-dir', t])]),
            ...(refresh === false ? ['-refresh=false'] : []),
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
