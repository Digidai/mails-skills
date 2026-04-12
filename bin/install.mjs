#!/usr/bin/env node

import { execSync } from 'child_process'
import { join, dirname } from 'path'
import { fileURLToPath } from 'url'

const __dirname = dirname(fileURLToPath(import.meta.url))
const installScript = join(__dirname, '..', 'install.sh')

try {
  execSync(`bash "${installScript}"`, { stdio: 'inherit' })
} catch (err) {
  process.exit(err.status || 1)
}
