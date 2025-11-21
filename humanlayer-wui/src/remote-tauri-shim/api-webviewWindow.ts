type UnlistenFn = () => void

export class WebviewWindow {
  label: string

  constructor(label: string, _options?: any) {
    this.label = label
  }

  static async getByLabel(label: string): Promise<WebviewWindow | null> {
    return new WebviewWindow(label)
  }

  async show() {
    return
  }

  async close() {
    return
  }

  async setFocus() {
    return
  }

  async center() {
    return
  }

  async onDragDropEvent(_handler: any): Promise<UnlistenFn> {
    return () => {}
  }
}
