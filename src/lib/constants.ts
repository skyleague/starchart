import findRoot from 'find-root'

export const rootDirectory = (() => {
    const root = findRoot(process.cwd())
    return root
})()
