import { bridgeRequest } from './bridge-client'

export async function invoke<T = any>(cmd: string, args?: Record<string, any>): Promise<T> {
  const res = await bridgeRequest<{ result: T }>('/invoke', {
    method: 'POST',
    body: { cmd, args: args || {} },
  })
  return res.result
}
