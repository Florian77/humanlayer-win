type UnlistenFn = () => void

export async function listen(_event: string, _handler: (event: any) => void): Promise<UnlistenFn> {
  return () => {}
}

export async function emit(_event: string, _payload?: any): Promise<void> {
  return
}
