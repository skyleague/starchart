import fs from 'node:fs/promises'
import path from 'node:path'
import type { Argv } from 'yargs'
import { StarchartConfiguration } from '../../lib/configuration.js'
import { rootDirectory } from '../../lib/constants.js'
import { openapi } from '../../lib/openapi.js'

export function builder(yargs: Argv) {
    return yargs
        .option('output', {
            type: 'string',
            default: '.',
        })
        .option('cwd', {
            type: 'string',
            default: rootDirectory,
            coerce: (cwd) => path.resolve(process.cwd(), cwd),
        })
}

export async function handler(argv: ReturnType<typeof builder>['argv']): Promise<void> {
    const { buildDir: _buildDir, artifactDir: _artifactDir, output, cwd } = await argv

    const configuration = await StarchartConfiguration.load({ cwd })
    if ('left' in configuration) {
        console.error(configuration.left)
        return
    }

    const openapiDocs = await openapi({ configuration: configuration.right, cwd })

    if (output !== undefined) {
        for (const [stackName, openapi] of Object.entries(openapiDocs)) {
            const filePath = path.join(output, `${stackName}.openapi.json`)
            await fs.mkdir(path.dirname(filePath), { recursive: true })
            await fs.writeFile(filePath, JSON.stringify(openapi, null, 2))
        }
    } else {
        console.log(JSON.stringify(openapiDocs, null, 2))
    }
}

export default {
    command: 'openapi',
    describe: 'Build OpenAPI',
    builder,
    handler,
}
