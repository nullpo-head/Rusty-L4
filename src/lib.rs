#![no_std]

use core::panic::PanicInfo;

mod vga_buffer;

#[no_mangle]
pub extern "C" fn rust_start() -> ! {
    println!("Hello Hello, World!\nsome numbers: {} {}", 42, 1.337);

    loop {}
}

#[panic_handler]
fn panic(info: &PanicInfo) -> ! {
    println!("{}", info);
    loop {}
}
