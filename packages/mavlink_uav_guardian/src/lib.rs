#![no_std]
use core::panic::PanicInfo;
use sentinel_sdk_rs::{PacketView, Verdict};

#[panic_handler]
fn panic(_info: &PanicInfo) -> ! {
    loop {}
}

#[no_mangle]
pub extern "C" fn sentinel_dissect(pkt_ptr: *const u8, len: u32) -> i32 {
    let pkt = unsafe { PacketView::from_raw(pkt_ptr, len as usize) };
    if pkt.len() < 12 {
        return Verdict::Pass as i32;
    }
    let magic = pkt.get_u8(0);
    if magic == Some(0xFD) {
        let msg_id = (pkt.get_u8(7).unwrap_or(0) as u32)
            | ((pkt.get_u8(8).unwrap_or(0) as u32) << 8)
            | ((pkt.get_u8(9).unwrap_or(0) as u32) << 16);
        if msg_id == 76 {
            return Verdict::KernelDrop as i32;
        }
    } else if magic == Some(0xFE) {
        let msg_id = pkt.get_u8(5).unwrap_or(0);
        if msg_id == 76 {
            return Verdict::KernelDrop as i32;
        }
    }
    Verdict::Pass as i32
}
