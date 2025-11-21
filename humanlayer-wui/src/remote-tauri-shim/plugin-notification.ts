type Permission = 'granted' | 'denied' | 'default'

function getBrowserPermission(): Permission {
  if (typeof Notification === 'undefined') return 'denied'
  return Notification.permission
}

export async function isPermissionGranted(): Promise<boolean> {
  return getBrowserPermission() === 'granted'
}

export async function requestPermission(): Promise<Permission> {
  if (typeof Notification === 'undefined' || !Notification.requestPermission) {
    return 'denied'
  }
  return Notification.requestPermission()
}

type NotificationInput = string | { title: string; body?: string }

function showBrowserNotification(payload: NotificationInput) {
  if (typeof Notification === 'undefined') return
  const permission = Notification.permission
  if (permission !== 'granted') return

  if (typeof payload === 'string') {
    new Notification(payload)
    return
  }

  new Notification(payload.title, { body: payload.body })
}

export async function sendNotification(payload: NotificationInput): Promise<void> {
  showBrowserNotification(payload)
}

export async function sendNonBlockingNotification(payload: NotificationInput): Promise<void> {
  showBrowserNotification(payload)
}
