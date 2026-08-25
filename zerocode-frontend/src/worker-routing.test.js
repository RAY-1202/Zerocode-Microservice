import assert from 'node:assert/strict'
import { apiPort } from './worker-routing.js'

assert.equal(apiPort('/api/user/login'), 8124)
assert.equal(apiPort('/api/app/add'), 8125)
assert.equal(apiPort('/api/userland'), 8125)
