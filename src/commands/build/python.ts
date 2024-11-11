import { execSync } from 'node:child_process'
import fs from 'node:fs'
import path from 'node:path'
import { spawnAsync } from '@skyleague/esbuild-lambda'
import type { HandlerConfiguration, StackConfiguration } from '../../lib/configuration.js'
import { rootDirectory } from '../../lib/constants.js'

export async function buildPython(
    groupedHandlers: Record<'nodejs' | 'python' | 'unknown', HandlerConfiguration[]>,
    buildDir: string,
) {
    const seenStacks = new WeakSet()
    const uniqueStacks: StackConfiguration[] = []
    for (const handler of groupedHandlers.python) {
        if (seenStacks.has(handler.stack)) {
            continue
        }
        seenStacks.add(handler.stack)
        uniqueStacks.push(handler.stack)
    }

    const pluginsOutput = execSync('poetry self show plugins', { cwd: rootDirectory, stdio: 'pipe' }).toString()
    if (!pluginsOutput.includes('poetry-plugin-export')) {
        await spawnAsync('poetry', ['self', 'add', 'poetry-plugin-export'], {
            cwd: rootDirectory,
            stdio: 'inherit',
        })
        await spawnAsync('poetry', ['config', 'warnings.export', 'false'], {
            cwd: rootDirectory,
            stdio: 'inherit',
        })
    }

    const stackRequirements = new WeakMap<StackConfiguration, string>()
    // Check for pyproject.toml and export requirements in parallel
    await Promise.all(
        uniqueStacks.map(async (stack) => {
            const stackRoot = path.dirname(path.relative(rootDirectory, stack.target))

            const poetryFile = path.join(path.dirname(stack.target), 'pyproject.toml')
            if (fs.existsSync(poetryFile)) {
                // Export poetry requirements
                const requirementsPath = path.join(buildDir, stackRoot, 'requirements.txt')
                await fs.promises.mkdir(path.join(buildDir, stackRoot), { recursive: true })
                await spawnAsync('poetry', ['export', '-f', 'requirements.txt', '-o', requirementsPath, '--without-hashes'], {
                    cwd: path.dirname(stack.target),
                    stdio: 'inherit',
                })
                stackRequirements.set(stack, (await fs.promises.readFile(requirementsPath)).toString())
            }
        }),
    )

    // Write requirements.txt for each handler in parallel and install them
    await Promise.all(
        groupedHandlers.python.map(async (handler) => {
            const handlerDir = path.dirname(handler.path)
            const buildHandlerDir = path.join(buildDir, path.relative(rootDirectory, handlerDir))
            const absoluteStackRoot = path.dirname(handler.stack.target)
            await fs.promises.mkdir(buildHandlerDir, { recursive: true })

            // Get the stack requirements for this handler
            const stackReqs = stackRequirements.get(handler.stack) || ''

            // Check for handler-specific requirements
            const handlerReqsPath = path.join(handlerDir, 'requirements.txt')
            let handlerReqs = ''
            if (fs.existsSync(handlerReqsPath)) {
                handlerReqs = (await fs.promises.readFile(handlerReqsPath)).toString()
            }

            // Write combined requirements
            if (stackReqs || handlerReqs) {
                const handlerRequirements = path.join(buildHandlerDir, 'requirements.txt')
                await fs.promises.writeFile(handlerRequirements, `${stackReqs}\n${handlerReqs}`)
                // Install requirements
                await spawnAsync(
                    'pip',
                    [
                        'install',
                        '--platform',
                        'manylinux2014_aarch64',
                        '--only-binary=:all:',
                        '--python-version',
                        handler.handler.runtime?.replace(/^python|\.|-/g, '') || '310',
                        '-r',
                        handlerRequirements,
                        '-t',
                        buildHandlerDir,
                    ],
                    {
                        stdio: 'inherit',
                    },
                )
            }

            // Copy source files to build directory
            const handlerSourceDir = path.dirname(handler.stack.target)
            const lambdaName = path.basename(handlerDir)
            await fs.promises.cp(handlerSourceDir, path.join(buildHandlerDir, lambdaName), {
                recursive: true,
                force: true,
            })

            // Create handler.py that imports the handler function
            const handlerEndpoint = path.basename(handler.endpoint)
            const handlerPath = path.join(buildHandlerDir, handlerEndpoint)
            const handlerName = `${lambdaName}.${path.relative(absoluteStackRoot, handlerDir).replace(/\//g, '.')}`

            await fs.promises.writeFile(
                handlerPath,
                `from ${handlerName}.${handlerEndpoint.split('.')[0]} import ${handler.handler.handler?.split('.')[1]}`,
            )

            // Ensure __init__.py exists in all parent directories
            const parts = handlerName.split('.')
            let currentPath = path.join(buildDir, path.relative(rootDirectory, handlerDir))

            for (const part of parts) {
                currentPath = path.join(currentPath, part)
                const initPath = path.join(currentPath, '__init__.py')
                if (!fs.existsSync(initPath)) {
                    await fs.promises.writeFile(initPath, '')
                }
            }
        }),
    )
}
