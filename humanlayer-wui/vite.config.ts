import path from 'path'
import { defineConfig, PluginOption } from 'vite'
import react from '@vitejs/plugin-react'
import tailwindcss from '@tailwindcss/vite'
import { sentryVitePlugin } from '@sentry/vite-plugin'

const host = process.env.TAURI_DEV_HOST
const port = process.env.VITE_PORT ? parseInt(process.env.VITE_PORT) : 1420
const hmrPort = port + 1
const useRemoteTauriShim = process.env.VITE_REMOTE_TAURI_SHIM === '1'

// Determine if this is a Sentry-enabled build (has SENTRY_ORG configured)
const isSentryRelease = !!process.env.SENTRY_ORG && process.env.NODE_ENV === 'production'

/* React Dev Tools */
// https://eikowagenknecht.de/posts/using-react-devtools-with-tauri-v2-and-vite/
// https://react.dev/learn/react-developer-tools
// npm i -g react-devtools and then launch `react-devtools` in a terminal while your Tauri app is running
const reactDevTools = (): PluginOption => {
  return {
    name: 'react-devtools',
    apply: 'serve', // Only apply this plugin during development
    transformIndexHtml(html) {
      return {
        html,
        tags: [
          {
            tag: 'script',
            attrs: {
              src: 'http://localhost:8097',
            },
            injectTo: 'head',
          },
        ],
      }
    },
  }
}

// https://vitejs.dev/config/
export default defineConfig(async () => ({
  plugins: [
    react(),
    reactDevTools(),
    tailwindcss(),

    // Sentry plugin only for builds with proper configuration
    ...(isSentryRelease
      ? [
          sentryVitePlugin({
            org: process.env.SENTRY_ORG!,
            project: process.env.SENTRY_PROJECT!,
            authToken: process.env.SENTRY_AUTH_TOKEN!,

            release: {
              // Use standardized version from CI/CD (e.g., "0.1.0-20250910-143022-nightly")
              // Falls back to package.json version or 'unknown' for local builds
              name: process.env.VITE_APP_VERSION || process.env.npm_package_version || 'unknown',
              uploadLegacySourcemaps: {
                paths: ['dist'],
              },
            },

            sourcemaps: {
              // Security: Remove source maps after upload so they don't get bundled
              filesToDeleteAfterUpload: ['**/*.js.map', '**/*.mjs.map'],
            },
          }),
        ]
      : []),
  ],

  resolve: {
    alias: (() => {
      const baseAliases: Record<string, string> = {
        '@': path.resolve(__dirname, './src'),
        '@humanlayer/hld-sdk': path.resolve(__dirname, '../hld/sdk/typescript/dist'),
      }

      /*if (!useRemoteTauriShim) {
        return baseAliases
      }*/

      console.log('*** STARTING WITH REMOTE TAURI SHIM ALIASES ***')

      const shim = (p: string) => path.resolve(__dirname, './src/remote-tauri-shim', p)

      return {
        ...baseAliases,
        '@tauri-apps/plugin-fs': shim('plugin-fs.ts'),
        '@tauri-apps/api/path': shim('api-path.ts'),
        '@tauri-apps/api/core': shim('api-core.ts'),
        '@tauri-apps/api/window': shim('api-window.ts'),
        '@tauri-apps/api/webview': shim('api-webview.ts'),
        '@tauri-apps/api/webviewWindow': shim('api-webviewWindow.ts'),
        '@tauri-apps/api/event': shim('api-event.ts'),
        '@tauri-apps/plugin-global-shortcut': shim('plugin-global-shortcut.ts'),
        '@tauri-apps/plugin-notification': shim('plugin-notification.ts'),
        '@tauri-apps/plugin-clipboard-manager': shim('plugin-clipboard-manager.ts'),
        '@tauri-apps/plugin-opener': shim('plugin-opener.ts'),
        '@tauri-apps/plugin-log': shim('plugin-log.ts'),
      }
    })(),
  },

  // Generate source maps for production builds (required for Sentry)
  build: {
    sourcemap: process.env.NODE_ENV === 'production',
    // Additional build optimizations
    rollupOptions: {
      output: {
        // Don't include source code in source maps (security)
        sourcemapExcludeSources: true,
      },
    },
  },

  // Vite options tailored for Tauri development and only applied in `tauri dev` or `tauri build`
  //
  // 1. prevent vite from obscuring rust errors
  clearScreen: false,
  // 2. tauri expects a fixed port, fail if that port is not available
  server: {
    port: port,
    strictPort: true,
    host: host || false,
    hmr: host
      ? {
          protocol: 'ws',
          host,
          port: hmrPort,
        }
      : undefined,
    watch: {
      // 3. tell vite to ignore watching `src-tauri`
      ignored: ['**/src-tauri/**', '**/*.test.ts'],
    },
  },
}))
