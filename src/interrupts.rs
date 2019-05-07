use x86_64::structures::idt::{InterruptDescriptorTable, InterruptStackFrame, PageFaultErrorCode};
use lazy_static::lazy_static;
use crate::println;


lazy_static! {
    static ref IDT: InterruptDescriptorTable = {
        let mut idt = InterruptDescriptorTable::new();
        idt.divide_by_zero.set_handler_fn(exception_handler);
        idt.breakpoint.set_handler_fn(exception_handler);
        /*unsafe {
            idt.double_fault.set_handler_fn(double_fault_handler)
                .set_stack_index(gdt::DOUBLE_FAULT_IST_INDEX);
        }*/
        idt
    };
}

pub fn init_idt() {
    IDT.load();
}

#[no_mangle]
extern "x86-interrupt" fn exception_handler(
    stack_frame: &mut InterruptStackFrame) 
{
    println!("EXCEPTION: \n{:#?}", stack_frame);
}

extern "x86-interrupt" fn double_fault_handler(
    stack_frame: &mut InterruptStackFrame,
    _: u64) 
{
    println!("EXCEPTION: DOUBLE FAULT\n{:#?}", stack_frame);
    loop {}
}

extern "x86-interrupt" fn fault_handler(
    stack_frame: &mut InterruptStackFrame,
    _: PageFaultErrorCode) 
{
    println!("EXCEPTION: \n{:#?}", stack_frame);
}
