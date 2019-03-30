#![no_std]
#![feature(abi_x86_interrupt)]
#![feature(asm)]

use core::panic::PanicInfo;

pub mod interrupts;
pub mod gdt;

mod vga_buffer;

#[no_mangle]
pub extern "C" fn rust_start() -> ! {
    println!("Hello Hello, World!\nsome numbers: {} {}", 42, 1.337);

    gdt::init();
    interrupts::init_idt();
    x86_64::instructions::interrupts::int3();
    /*unsafe {
        asm!("mov dx, 0; div dx" ::: "ax", "dx" : "volatile", "intel")
    }*/

    println!("It did not crash");

    loop {}
}

#[panic_handler]
fn panic(info: &PanicInfo) -> ! {
    println!("{}", info);
    loop {}
}

