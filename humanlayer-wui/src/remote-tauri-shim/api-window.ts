type UnlistenFn = () => void

const noop = () => {}
const noopAsync = async () => {}

function makeUnlisten(): UnlistenFn {
  return () => {}
}

export function getCurrentWindow() {
  return {
    async onResized(_handler?: any): Promise<UnlistenFn> {
      return makeUnlisten()
    },
    async onMoved(_handler?: any): Promise<UnlistenFn> {
      return makeUnlisten()
    },
    async onFocusChanged(handler?: (event: { payload: boolean }) => void): Promise<UnlistenFn> {
      if (handler) {
        // Simulate a focus notification once with current state
        handler({ payload: document.hasFocus ? document.hasFocus() : true })
      }
      return makeUnlisten()
    },
    async innerSize() {
      return { width: window.innerWidth || 1280, height: window.innerHeight || 720 }
    },
    async outerPosition() {
      return { x: 0, y: 0 }
    },
    async isMaximized() {
      return false
    },
    async close() {
      window.close()
    },
    async show() {
      return
    },
    async hide() {
      return
    },
    async center() {
      return
    },
    async maximize() {
      return
    },
    async unmaximize() {
      return
    },
    async setSkipTaskbar(_skip: boolean) {
      return
    },
    async setFocus() {
      return
    },
    async listen(_event: string, _handler: any): Promise<UnlistenFn> {
      return makeUnlisten()
    },
  }
}

export const appWindow = getCurrentWindow()

export default {
  getCurrentWindow,
  appWindow,
  onResized: noopAsync,
  onMoved: noopAsync,
  show: noopAsync,
  hide: noopAsync,
  close: noopAsync,
  center: noopAsync,
  maximize: noopAsync,
  unmaximize: noopAsync,
  setSkipTaskbar: noopAsync,
  setFocus: noopAsync,
}
