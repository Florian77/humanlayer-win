import { bridgeRequest } from './bridge-client'

export interface DirEntry {
  path?: string
  name?: string
  isFile: boolean
  isDirectory: boolean
  children?: DirEntry[]
}

interface ReadDirResponse {
  entries: DirEntry[]
}

export async function readDir(path: string): Promise<DirEntry[]> {
  const res = await bridgeRequest<ReadDirResponse>('/fs/readDir', { query: { path } })
  return res.entries || []
}

export async function exists(path: string): Promise<boolean> {
  const res = await bridgeRequest<{ exists: boolean }>('/fs/exists', { query: { path } })
  return !!res.exists
}
