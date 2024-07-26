import { run } from '../src/cli.js'

import { expect, it } from 'vitest'

it('main', () => {
    expect(run).toBeDefined()
})
