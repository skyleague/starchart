import { spawnSync } from 'node:child_process'
import fs from 'node:fs'
import os from 'node:os'
import path from 'node:path'
import { globby } from 'globby'
import type { Argv } from 'yargs'
import * as packageJson from '../../../package.json' with { type: 'json' }
import { builder as buildBuilder } from '../build/index.js'
const { version } = packageJson.default ?? packageJson
import { parallelLimit } from '@skyleague/axioms'

const _pLimit = parallelLimit(os.cpus().length * 4 + 1)

export function builder(yargs: Argv) {
    return buildBuilder(yargs).option('dir', {
        describe: 'terraform directory',
        type: 'string',
        default: '.',
        example: 'terraform',
        demandOption: true,
    })
}

export async function handler(argv: ReturnType<typeof builder>['argv']): Promise<void> {
    const { target, dir } = await argv
    const targets = target.flatMap((t) => t.split(','))
    const cwd = path.join(process.cwd(), dir)

    const files = (
        await globby(['**/*.hcl', '**/*.tf', '!.terragrunt-cache', '!.terraform', '!node_modules'], {
            cwd: cwd,
            onlyDirectories: false,
        })
    )
        .map((file) => path.join(cwd, file))
        .filter((file) => targets.includes('*') || targets.some((t) => file.includes(t)))

    const original = Object.fromEntries(await Promise.all(files.map((file) => _pLimit(() => readFileContents(file)))))

    const updatedFiles: string[] = []
    for (const [file, contents] of Object.entries(original)) {
        const updated = replaceSourceRefVersion(contents)
        if (updated !== contents) {
            console.log(`Updating starchart version in ${file}`)
            await fs.promises.writeFile(file, updated)
            updatedFiles.push(file)
        }
    }

    spawnSync('git', ['stage', '--patch', ...updatedFiles], { stdio: 'inherit', cwd })
    const diffFiles = spawnSync('git', ['diff', '--name-only', ...updatedFiles], { stdio: 'pipe', cwd })
        .stdout.toString()
        .split('\n')
        .map((f) => f.trim())
        .filter((f) => f.length > 0)

    for (const file of diffFiles) {
        const contents = original[file]
        if (contents !== undefined) {
            console.log(`Reverting changes to ${file}`)
            await fs.promises.writeFile(file, contents)
        }
    }
}

export default {
    command: 'update',
    describe: '[beta] update starchart to the latest version',
    builder,
    handler,
}

function replaceSourceRefVersion(contents: string) {
    return contents.replace(
        /(?<source>source\s*=\s*".*github\.com\/skyleague\/starchart.*)\?ref=(?<version>.*)/g,
        `$<source>?ref=v${version}"`,
    )
}

async function readFileContents(file: string): Promise<[string, string]> {
    const contents = await fs.promises.readFile(file, 'utf-8')
    return [file, contents]
}
