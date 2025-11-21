import { bridgeRequest } from './bridge-client'

export async function homeDir(): Promise<string> {
  const res = await bridgeRequest<{ homeDir: string }>('/path/homeDir')
  return res.homeDir
}

export async function appLogDir(): Promise<string> {
  const res = await bridgeRequest<{ appLogDir: string }>('/path/appLogDir')
  return res.appLogDir
}
