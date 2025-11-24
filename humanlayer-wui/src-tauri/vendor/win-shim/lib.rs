#[cfg(unix)]
mod unix {
    use libc::{kill, SIGTERM};
    #[derive(Clone, Copy, Debug)]
    pub struct Pid(pub i32);
    impl Pid {
        pub fn from_raw(v: i32) -> Self { Pid(v) }
    }
    #[derive(Debug, Clone, Copy)]
    pub enum Signal { SIGTERM }
    #[derive(Debug)]
    pub struct Errno(std::io::Error);
    impl std::fmt::Display for Errno { fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result { self.0.fmt(f) } }
    impl std::error::Error for Errno {}
    pub fn kill(pid: Pid, _sig: Signal) -> Result<(), Errno> {
        let rc = unsafe { kill(pid.0, SIGTERM) };
        if rc == 0 { Ok(()) } else { Err(Errno(std::io::Error::last_os_error())) }
    }
    pub mod sys {
        pub mod signal {
            pub use super::super::{kill, Signal, Errno};
        }
        pub use signal::*;
    }
    pub mod unistd { pub use super::Pid; }
}
#[cfg(unix)]
pub use unix::*;

#[cfg(windows)]
mod win {
    use windows_sys::Win32::System::Threading::{OpenProcess, TerminateProcess, PROCESS_TERMINATE};
    use windows_sys::Win32::Foundation::CloseHandle;
    #[derive(Clone, Copy, Debug)]
    pub struct Pid(pub i32);
    impl Pid { pub fn from_raw(v: i32) -> Self { Pid(v) } }
    #[derive(Debug, Clone, Copy)]
    pub enum Signal { SIGTERM }
    #[derive(Debug)]
    pub struct Errno(std::io::Error);
    impl std::fmt::Display for Errno { fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result { self.0.fmt(f) } }
    impl std::error::Error for Errno {}
    pub fn kill(pid: Pid, _sig: Signal) -> Result<(), Errno> {
        unsafe {
            let handle = OpenProcess(PROCESS_TERMINATE, 0, pid.0 as u32);
            if handle.is_null() {
                return Err(Errno(std::io::Error::last_os_error()));
            }
            let ok = TerminateProcess(handle, 1);
            CloseHandle(handle);
            if ok == 0 {
                Err(Errno(std::io::Error::last_os_error()))
            } else {
                Ok(())
            }
        }
    }
    pub mod sys {
        pub mod signal {
            pub use super::super::{kill, Signal, Errno};
        }
        pub use signal::*;
    }
    pub mod unistd { pub use super::Pid; }
}
#[cfg(windows)]
pub use win::*;
