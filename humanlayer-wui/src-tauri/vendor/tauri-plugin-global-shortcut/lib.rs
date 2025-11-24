use tauri::{plugin::Plugin, AppHandle, Runtime};

pub struct Builder;

impl Builder {
    pub fn new() -> Self {
        Self
    }

    pub fn build(self) -> GlobalShortcutPlugin {
        GlobalShortcutPlugin
    }
}

#[derive(Default, Clone, Copy)]
pub struct GlobalShortcutPlugin;

impl<R: Runtime> Plugin<R> for GlobalShortcutPlugin {
    fn name(&self) -> &'static str {
        "global-shortcut"
    }
}

pub struct GlobalShortcutManager<R: Runtime> {
    _app: AppHandle<R>,
}

impl<R: Runtime> GlobalShortcutManager<R> {
    pub fn on_shortcut<F: Fn(&AppHandle<R>, String, String) + Send + 'static>(
        &self,
        _accel: impl Into<String>,
        _cb: F,
    ) -> Result<(), String> {
        // No-op shim for platforms where registering global shortcuts fails or is unsupported
        Ok(())
    }
}

pub trait GlobalShortcutExt<R: Runtime> {
    fn global_shortcut(&self) -> GlobalShortcutManager<R>;
}

impl<R: Runtime> GlobalShortcutExt<R> for tauri::AppHandle<R> {
    fn global_shortcut(&self) -> GlobalShortcutManager<R> {
        GlobalShortcutManager { _app: self.clone() }
    }
}
