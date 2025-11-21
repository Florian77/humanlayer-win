import { execSync } from 'child_process'
import * as fs from 'fs'
import * as path from 'path'

export function getInvocationName(): string {
  // For compiled bun binaries, argv[1] is the binary path
  // For node scripts, argv[1] is the script path
  // We want the base name of whichever is the actual invocation
  const invocationPath = process.argv[1] || process.argv[0]
  return path.basename(invocationPath)
}

export function getDefaultSocketPath(invocationName: string): string {
  const isWindows = process.platform === 'win32'
  const baseTcp = isWindows ? 'tcp://127.0.0.1:' : '~/.humanlayer/'

  // Use nightly socket for nightly variants
  if (invocationName === 'codelayer-nightly' || invocationName === 'humanlayer-nightly') {
    return isWindows ? `${baseTcp}17889` : `${baseTcp}daemon-nightly.sock`
  }
  // Use regular socket for all other invocations
  return isWindows ? `${baseTcp}17888` : `${baseTcp}daemon.sock`
}

export function shouldLaunchApp(invocationName: string, hasArgs: boolean): boolean {
  // Launch app only if invoked as codelayer/codelayer-nightly with NO arguments
  // Note: commander will have already parsed --help, --version, etc.
  return (invocationName === 'codelayer' || invocationName === 'codelayer-nightly') && !hasArgs
}

export function getAppPath(invocationName: string): string | null {
  const isNightly = invocationName === 'codelayer-nightly'
  const appName = isNightly ? 'CodeLayer-Nightly' : 'CodeLayer'
  const appPath = `/Applications/${appName}.app`

  if (fs.existsSync(appPath)) {
    return appPath
  }

  // Fallback: check if installed via Homebrew Caskroom
  const caskPath = `/opt/homebrew/Caskroom/${isNightly ? 'codelayer-nightly' : 'codelayer'}`
  if (fs.existsSync(caskPath)) {
    // Find the latest version
    const versions = fs.readdirSync(caskPath).filter(v => !v.startsWith('.'))
    if (versions.length > 0) {
      const latestVersion = versions.sort().pop()
      const caskAppPath = `${caskPath}/${latestVersion}/${appName}.app`
      if (fs.existsSync(caskAppPath)) {
        return caskAppPath
      }
    }
  }

  return null
}

export function launchApp(appPath: string): void {
  console.log(`Opening ${appPath}`)
  console.log(`For more options run:`)
  console.log(`    ${getInvocationName()} --help`)

  try {
    execSync(`open "${appPath}"`, { stdio: 'inherit' })
  } catch (error) {
    console.error(`Failed to open application: ${error}`)
    process.exit(1)
  }
}
