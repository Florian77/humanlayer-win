import { createServer, IncomingMessage, ServerResponse } from 'http'
import { parse } from 'url'
import { promises as fs, constants as fsConstants, createWriteStream } from 'fs'
import path from 'path'
import os from 'os'
import { spawn, ChildProcessWithoutNullStreams } from 'child_process'

const PORT = parseInt(process.env.HUMANLAYER_REMOTE_BRIDGE_PORT || '17650', 10)
const repoRoot = path.resolve(__dirname, '..', '..')
const humanlayerDir = path.join(os.homedir(), '.humanlayer')
const windowStatePath = path.join(humanlayerDir, 'bridge-window-state.json')
const DEBUG = process.env.HUMANLAYER_REMOTE_BRIDGE_DEBUG === '1'
const AUTOSTART_DAEMON = process.env.HUMANLAYER_REMOTE_BRIDGE_AUTOSTART !== '0'
const LOG_BASE = process.env.HUMANLAYER_REMOTE_BRIDGE_LOG_BASE
  ? expandHome(process.env.HUMANLAYER_REMOTE_BRIDGE_LOG_BASE)
  : path.join(humanlayerDir, 'logs', 'remote-bridge')

// Prepare bridge log stream
let bridgeLogStream: any = null
  ; (async () => {
    try {
      await fs.mkdir(LOG_BASE, { recursive: true })
      const ts = new Date().toISOString().replace(/[:.]/g, '-')
      const bridgeLogFile = path.join(LOG_BASE, `bridge-${ts}.log`)
      bridgeLogStream = createWriteStream(bridgeLogFile, { flags: 'a' })

      const origLog = console.log
      const origError = console.error
      console.log = (...args: any[]) => {
        origLog(...args)
        if (bridgeLogStream) {
          bridgeLogStream.write(args.map(a => (typeof a === 'string' ? a : JSON.stringify(a))).join(' ') + '\n')
        }
      }
      console.error = (...args: any[]) => {
        origError(...args)
        if (bridgeLogStream) {
          bridgeLogStream.write(args.map(a => (typeof a === 'string' ? a : JSON.stringify(a))).join(' ') + '\n')
        }
      }

      process.on('exit', () => {
        if (bridgeLogStream) bridgeLogStream.end()
      })
      process.on('SIGINT', () => {
        if (bridgeLogStream) bridgeLogStream.end()
        process.exit()
      })
    } catch (e) {
      console.error('[BRG] failed to init bridge log stream', e)
    }
  })()

type DaemonInfo = {
  port: number
  pid: number
  database_path: string
  socket_path: string
  branch_id: string
  is_running: boolean
}

let daemonProcess: ChildProcessWithoutNullStreams | null = null
let daemonInfo: DaemonInfo | null = null

function sendJson(res: ServerResponse, status: number, data: any) {
  res.statusCode = status
  res.setHeader('Content-Type', 'application/json')
  res.end(JSON.stringify(data))
}

async function readBody(req: IncomingMessage): Promise<any> {
  return new Promise((resolve, reject) => {
    const chunks: Buffer[] = []
    req
      .on('data', chunk => chunks.push(chunk))
      .on('end', () => {
        if (!chunks.length) return resolve({})
        try {
          const parsed = JSON.parse(Buffer.concat(chunks).toString('utf8'))
          resolve(parsed)
        } catch (e) {
          reject(e)
        }
      })
      .on('error', reject)
  })
}

function expandHome(p: string) {
  if (p.startsWith('~')) {
    return path.join(os.homedir(), p.slice(1))
  }
  return p
}

async function handleReadDir(res: ServerResponse, dirPath?: string) {
  if (!dirPath) return sendJson(res, 400, { error: 'path is required' })
  const target = expandHome(dirPath)
  try {
    const entries = await fs.readdir(target, { withFileTypes: true })
    const data = entries.map(entry => ({
      path: path.join(target, entry.name),
      name: entry.name,
      isFile: entry.isFile(),
      isDirectory: entry.isDirectory(),
    }))
    return sendJson(res, 200, { entries: data })
  } catch (error: any) {
    return sendJson(res, 500, { error: error.message })
  }
}

async function handleExists(res: ServerResponse, targetPath?: string) {
  if (!targetPath) return sendJson(res, 400, { error: 'path is required' })
  try {
    await fs.access(expandHome(targetPath))
    return sendJson(res, 200, { exists: true })
  } catch {
    return sendJson(res, 200, { exists: false })
  }
}

function defaultLogDir() {
  return path.join(humanlayerDir, 'logs')
}

function defaultLogFile() {
  const branch = process.env.HUMANLAYER_BRIDGE_BRANCH || 'dev'
  return path.join(defaultLogDir(), `wui-${branch}`, 'codelayer.log')
}

async function readLastLogLines(filePath?: string, n: number = 200): Promise<string> {
  const target = filePath ? expandHome(filePath) : defaultLogFile()
  try {
    const content = await fs.readFile(target, 'utf8')
    const lines = content.split('\n')
    return lines.slice(-n).join('\n')
  } catch {
    return ''
  }
}

async function saveWindowState(state: any) {
  await fs.mkdir(humanlayerDir, { recursive: true })
  await fs.writeFile(windowStatePath, JSON.stringify(state, null, 2), 'utf8')
}

async function loadWindowState() {
  try {
    const raw = await fs.readFile(windowStatePath, 'utf8')
    return JSON.parse(raw)
  } catch {
    return null
  }
}

async function fileExists(p: string): Promise<boolean> {
  try {
    await fs.access(p, fsConstants.X_OK)
    return true
  } catch {
    return false
  }
}


async function resolveDaemonBinary(): Promise<string> {
  const override = process.env.HUMANLAYER_REMOTE_BRIDGE_DAEMON_BIN
  if (override) return expandHome(override)

  const dev = path.join(repoRoot, 'hld', 'hld-dev')
  const prod = path.join(repoRoot, 'hld', 'hld')

  if (await fileExists(dev)) return dev
  if (await fileExists(prod)) return prod

  throw new Error('No daemon binary found (expected hld-dev or hld)')
}

async function startDaemon(args: any): Promise<DaemonInfo> {
  if (daemonProcess && daemonInfo) {
    return daemonInfo
  }

  const desiredPort =
    Number(args?.port) ||
    Number(process.env.HUMANLAYER_REMOTE_BRIDGE_DAEMON_PORT || '') ||
    7777

  const socketPath = expandHome(
    args?.socketPath || path.join(humanlayerDir, 'daemon-remote.sock'),
  )
  const databasePath = expandHome(
    args?.databasePath || path.join(humanlayerDir, 'daemon-remote.db'),
  )
  const branchId = args?.branchId || process.env.HUMANLAYER_BRIDGE_BRANCH || 'remote-bridge'
  const bin = await resolveDaemonBinary()
  console.log(`[BRG] daemon binary: ${bin}`)

  await fs.mkdir(path.dirname(databasePath), { recursive: true })
  await fs.mkdir(path.dirname(socketPath), { recursive: true })
  await fs.mkdir(LOG_BASE, { recursive: true })

  const env = {
    ...process.env,
    HUMANLAYER_DAEMON_HTTP_PORT: String(desiredPort),
    HUMANLAYER_DAEMON_HTTP_HOST: '0.0.0.0',
    HUMANLAYER_DAEMON_SOCKET: socketPath,
    HUMANLAYER_DATABASE_PATH: databasePath,
    HUMANLAYER_DAEMON_VERSION_OVERRIDE: branchId,
    HUMANLAYER_LOG_LEVEL: process.env.HUMANLAYER_LOG_LEVEL || 'debug',
    HUMANLAYER_DEBUG: process.env.HUMANLAYER_DEBUG || 'true',
    GIN_MODE: process.env.GIN_MODE || 'debug',
  }

  const timestamp = new Date().toISOString().replace(/[:.]/g, '-')
  const logFile = path.join(LOG_BASE, `daemon-remote-${timestamp}.log`)
  const logStream = createWriteStream(logFile, { flags: 'a' })

  const child = spawn(bin, [], {
    env,
    stdio: ['ignore', 'pipe', 'pipe'],
  })

  let actualPort = desiredPort

  // Collect stdout/stderr, write to file, and prefix each emitted line
  let stdoutBuffer = ''
  child.stdout.on('data', chunk => {
    logStream.write(chunk)

    stdoutBuffer += chunk.toString()
    const lines = stdoutBuffer.split(/\r?\n/)
    stdoutBuffer = lines.pop() ?? ''

    for (const line of lines) {
      if (!line.trim()) continue

      // Echo daemon stdout with a consistent prefix
      process.stderr.write(`[DMN] ${line}\n`)

      const match = line.match(/HTTP_PORT=(\d+)/)
      if (match) {
        actualPort = Number(match[1])
        if (daemonInfo) {
          daemonInfo.port = actualPort
        }
      }
    }
  })
  child.stdout.on('end', () => {
    if (stdoutBuffer.trim()) {
      process.stderr.write(`[DMN] ${stdoutBuffer}\n`)
      const match = stdoutBuffer.match(/HTTP_PORT=(\d+)/)
      if (match) {
        actualPort = Number(match[1])
        if (daemonInfo) {
          daemonInfo.port = actualPort
        }
      }
    }
  })

  let stderrBuffer = ''
  child.stderr.on('data', chunk => {
    logStream.write(chunk)

    stderrBuffer += chunk.toString()
    const lines = stderrBuffer.split(/\r?\n/)
    stderrBuffer = lines.pop() ?? ''

    for (const line of lines) {
      if (!line.trim()) continue
      process.stderr.write(`[DMN] ${line}\n`)
    }
  })
  child.stderr.on('end', () => {
    if (stderrBuffer.trim()) {
      process.stderr.write(`[DMN] ${stderrBuffer}\n`)
    }
  })

  child.on('exit', code => {
    logStream.end()
    daemonProcess = null
    if (daemonInfo) {
      daemonInfo.is_running = false
    }
    console.warn(`[BRG] daemon exited with code ${code}`)
  })

  daemonProcess = child
  daemonInfo = {
    port: actualPort,
    pid: child.pid ?? 0,
    database_path: databasePath,
    socket_path: socketPath,
    branch_id: branchId,
    is_running: true,
  }

  return daemonInfo
}

async function stopDaemon(): Promise<void> {
  if (daemonProcess) {
    daemonProcess.kill()
    daemonProcess = null
  }
  if (daemonInfo) {
    daemonInfo.is_running = false
  }
}

async function getDaemonInfo(): Promise<DaemonInfo | null> {
  if (daemonInfo) return daemonInfo
  return null
}

async function handleInvoke(res: ServerResponse, body: any) {
  const { cmd, args } = body || {}
  try {
    switch (cmd) {
      case 'get_log_directory':
        return sendJson(res, 200, { result: defaultLogDir() })
      case 'read_last_log_lines': {
        const n = args?.n ?? 200
        const content = await readLastLogLines(args?.log_path, n)
        return sendJson(res, 200, { result: content })
      }
      case 'save_window_state': {
        await saveWindowState(args?.state || {})
        return sendJson(res, 200, { result: null })
      }
      case 'load_window_state': {
        const state = await loadWindowState()
        return sendJson(res, 200, { result: state })
      }
      case 'start_daemon': {
        const info = await startDaemon(args || {})
        return sendJson(res, 200, { result: info })
      }
      case 'stop_daemon': {
        await stopDaemon()
        return sendJson(res, 200, { result: null })
      }
      case 'get_daemon_info': {
        const info = await getDaemonInfo()
        return sendJson(res, 200, { result: info })
      }
      case 'is_daemon_running': {
        return sendJson(res, 200, { result: !!daemonProcess })
      }
      case 'get_stored_configs': {
        return sendJson(res, 200, { result: [] })
      }
      case 'get_config_path': {
        const configPath = path.join(os.homedir(), '.config', 'humanlayer', 'humanlayer.json')
        return sendJson(res, 200, { result: configPath })
      }
      default:
        return sendJson(res, 400, { error: `Unknown command ${cmd}` })
    }
  } catch (error: any) {
    return sendJson(res, 500, { error: error.message })
  }
}

const server = createServer(async (req, res) => {
  const url = parse(req.url || '', true)
  const pathname = url.pathname || '/'

  // Basic request logging when enabled
  if (DEBUG) {
    console.log(
      `[BRG] ${req.method} ${pathname} ${url.search || ''}` +
      (req.headers['content-length'] ? ` len=${req.headers['content-length']}` : ''),
    )
  }

  // Basic CORS for dev convenience
  res.setHeader('Access-Control-Allow-Origin', '*')
  res.setHeader('Access-Control-Allow-Methods', 'GET,POST,OPTIONS')
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type')
  if (req.method === 'OPTIONS') {
    res.statusCode = 204
    return res.end()
  }

  if (pathname === '/health') {
    return sendJson(res, 200, { ok: true })
  }

  if (pathname === '/path/homeDir' && req.method === 'GET') {
    return sendJson(res, 200, { homeDir: os.homedir() })
  }

  if (pathname === '/path/appLogDir' && req.method === 'GET') {
    return sendJson(res, 200, { appLogDir: defaultLogDir() })
  }

  if (pathname === '/fs/readDir' && req.method === 'GET') {
    return handleReadDir(res, url.query.path as string | undefined)
  }

  if (pathname === '/fs/exists' && req.method === 'GET') {
    return handleExists(res, url.query.path as string | undefined)
  }

  if (pathname === '/log/read-lines' && req.method === 'POST') {
    try {
      const body = await readBody(req)
      const content = await readLastLogLines(body?.path, body?.n)
      return sendJson(res, 200, { content })
    } catch (error: any) {
      return sendJson(res, 500, { error: error.message })
    }
  }

  if (pathname === '/invoke' && req.method === 'POST') {
    try {
      const body = await readBody(req)
      if (DEBUG) {
        console.log(`[BRG] invoke body: ${JSON.stringify(body)}`)
      }
      return handleInvoke(res, body)
    } catch (error: any) {
      if (DEBUG) {
        console.error('[BRG] invoke error', error)
      }
      return sendJson(res, 500, { error: error.message })
    }
  }

  return sendJson(res, 404, { error: 'Not found' })
})

server.listen(PORT, () => {
  console.log(`[BRG] listening on http://localhost:${PORT}`)
  console.log(`[BRG] repo root: ${repoRoot}`)

  // Optional daemon autostart
  if (AUTOSTART_DAEMON) {
    const envPort = Number(process.env.HUMANLAYER_REMOTE_PORT || '0') || 7777
    const envSocket = process.env.HUMANLAYER_REMOTE_SOCKET || path.join(humanlayerDir, 'daemon-remote.sock')
    const envDb = process.env.HUMANLAYER_REMOTE_DB || path.join(humanlayerDir, 'daemon-remote.db')
    const envBranch = process.env.HUMANLAYER_BRIDGE_BRANCH || 'remote-bridge'

    startDaemon({
      port: envPort,
      socketPath: envSocket,
      databasePath: envDb,
      branchId: envBranch,
    }).then(info => {
      console.log(
        `[BRG] autostart daemon OK: port=${info.port} socket=${info.socket_path} db=${info.database_path} branch=${info.branch_id}`,
      )
    }).catch(err => {
      console.error('[BRG] autostart daemon failed:', err)
    })
  } else {
    console.log('[BRG] daemon autostart disabled (HUMANLAYER_REMOTE_BRIDGE_AUTOSTART=0)')
  }
})
