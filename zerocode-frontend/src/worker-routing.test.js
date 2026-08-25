import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import { apiPort } from './worker-routing.js'

assert.equal(apiPort('/api/user/login'), 8124)
assert.equal(apiPort('/api/app/add'), 8125)
assert.equal(apiPort('/api/userland'), 8125)

const wrangler = JSON.parse(
  readFileSync(new URL('../wrangler.jsonc', import.meta.url), 'utf8'),
)
assert.deepEqual(wrangler.assets.run_worker_first, ['/api/*'])
