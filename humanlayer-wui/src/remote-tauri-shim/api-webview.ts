type UnlistenFn = () => void

const makeUnlisten = (): UnlistenFn => () => {}

export function getCurrentWebview() {
  return {
    async onDragDropEvent(_handler: any): Promise<UnlistenFn> {
      return makeUnlisten()
    },
  }
}
