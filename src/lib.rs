#![no_std]
#![feature(abi_x86_interrupt)]
#![feature(asm)]

use core::panic::PanicInfo;

extern crate multiboot2;

pub mod interrupts;
pub mod gdt;

mod vga_buffer;

#[no_mangle]
pub extern "C" fn rust_start(multiboot_info_addr: usize) -> ! {
    println!("Hello Hello, World!\nsome numbers: {} {}", 42, 1.337);

    gdt::init();
    interrupts::init_idt();

    println!("multiboot_info_addr: 0x{:x}", multiboot_info_addr);
    let boot_info = unsafe { multiboot2::load(multiboot_info_addr + 0xffffffffc0000000usize) };
    let memory_map_tag = boot_info.memory_map_tag()
        .expect("Memory map tag required");

    println!("memory areas:");
    for area in memory_map_tag.memory_areas() {
        println!("    start: 0x{:x}, length: 0x{:x}",
                 area.start_address(), area.size());
    }

    loop {}
}

#[panic_handler]
fn panic(info: &PanicInfo) -> ! {
    println!("{}", info);
    loop {}
}

