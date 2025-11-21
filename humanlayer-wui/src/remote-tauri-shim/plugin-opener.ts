export async function openUrl(url: string): Promise<void> {
  if (typeof window !== 'undefined' && window.open) {
    window.open(url, '_blank', 'noreferrer')
  }
}

export async function openPath(_path: string): Promise<void> {
  // Not supported in browser/shim mode; no-op to keep callers safe.
  return
}
