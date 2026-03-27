#!/usr/bin/env node

import { readFileSync, writeFileSync, mkdirSync, existsSync } from 'fs'
import { join, dirname } from 'path'
import { fileURLToPath } from 'url'
import { homedir } from 'os'

const __dirname = dirname(fileURLToPath(import.meta.url))
const SKILLS_DIR = join(__dirname, '..', 'skills')

const green = (s) => `\x1b[32m${s}\x1b[0m`
const yellow = (s) => `\x1b[33m${s}\x1b[0m`
const bold = (s) => `\x1b[1m${s}\x1b[0m`
const dim = (s) => `\x1b[2m${s}\x1b[0m`

console.log('')
console.log(bold('mails-skills') + dim(' — email for AI agents'))
console.log('')

// --- Detect platform ---
const home = homedir()
let platform = null

if (existsSync(join(home, '.claude'))) {
  platform = 'claude-code'
  console.log(green('✓') + ' Detected: Claude Code')
}
if (existsSync(join(home, '.openclaw')) || existsSync(join(home, 'openclaw'))) {
  if (platform) {
    console.log(green('✓') + ' Detected: OpenClaw (also found)')
  } else {
    platform = 'openclaw'
    console.log(green('✓') + ' Detected: OpenClaw')
  }
}

if (!platform) {
  platform = 'claude-code' // default
  console.log(dim('  No platform detected, defaulting to Claude Code'))
}

// --- Auto-detect mails config ---
const configPath = join(home, '.mails', 'config.json')
let workerUrl = ''
let authToken = ''
let mailbox = ''

if (existsSync(configPath)) {
  try {
    const config = JSON.parse(readFileSync(configPath, 'utf-8'))
    workerUrl = config.worker_url || ''
    authToken = config.api_key || config.worker_token || ''
    mailbox = config.mailbox || config.default_from || ''

    // Hosted users may not have worker_url
    if (!workerUrl && authToken) {
      workerUrl = 'https://mails-worker.genedai.workers.dev'
    }

    if (workerUrl && authToken && mailbox) {
      console.log(green('✓') + ' Found mails config')
      console.log(dim(`  Mailbox: ${mailbox}`))
    }
  } catch {}
}

// --- Install skill ---
console.log('')

if (platform === 'claude-code') {
  const skillSrc = join(SKILLS_DIR, 'claude-code', 'email.md')
  const skillDir = join(home, '.claude', 'skills')
  const skillDst = join(skillDir, 'email.md')

  mkdirSync(skillDir, { recursive: true })

  let content = readFileSync(skillSrc, 'utf-8')

  // Replace placeholders if config found
  if (workerUrl) content = content.replace(/YOUR_WORKER_URL/g, workerUrl)
  if (authToken) content = content.replace(/YOUR_AUTH_TOKEN/g, authToken)
  if (mailbox) content = content.replace(/YOUR_MAILBOX/g, mailbox)

  writeFileSync(skillDst, content)
  console.log(green('✓') + ` Skill installed to ${dim(skillDst)}`)

} else if (platform === 'openclaw') {
  const skillSrc = join(SKILLS_DIR, 'openclaw', 'SKILL.md')
  let skillDir = null

  for (const dir of [join(home, '.openclaw', 'skills'), join(home, 'openclaw', 'skills')]) {
    if (existsSync(dirname(dir))) {
      skillDir = join(dir, 'email')
      break
    }
  }

  if (!skillDir) {
    skillDir = join(process.cwd(), 'email')
  }

  mkdirSync(skillDir, { recursive: true })
  const content = readFileSync(skillSrc, 'utf-8')
  writeFileSync(join(skillDir, 'SKILL.md'), content)
  console.log(green('✓') + ` Skill installed to ${dim(join(skillDir, 'SKILL.md'))}`)

  // Write env vars hint
  if (workerUrl && authToken && mailbox) {
    console.log('')
    console.log(yellow('  Add to your shell profile:'))
    console.log(dim(`  export MAILS_API_URL="${workerUrl}"`))
    console.log(dim(`  export MAILS_AUTH_TOKEN="${authToken}"`))
    console.log(dim(`  export MAILS_MAILBOX="${mailbox}"`))
  }
}

// --- Verify connection ---
if (workerUrl && authToken) {
  console.log('')
  process.stdout.write(dim('  Verifying connection...'))
  try {
    const res = await fetch(`${workerUrl}/api/me`, {
      headers: { 'Authorization': `Bearer ${authToken}` },
      signal: AbortSignal.timeout(5000),
    })
    const data = await res.json()
    if (data.mailbox) {
      console.log(' ' + green('✓'))
      console.log(dim(`  Mailbox: ${data.mailbox}`))
      console.log(dim(`  Send: ${data.send ? 'enabled' : 'disabled'}`))
    } else {
      console.log(' ' + yellow('⚠ could not verify'))
    }
  } catch {
    console.log(' ' + yellow('⚠ could not reach worker'))
  }
}

// --- Done ---
console.log('')
console.log(green('✓') + bold(' Done!') + ' Your agent now has email.')
console.log('')
console.log(dim('  Tell your agent: "Check my inbox"'))
console.log('')
console.log(dim('  Docs: https://mails0.com'))
console.log(dim('  GitHub: https://github.com/Digidai/mails-skills'))
console.log('')
