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

    // Check MAVLink v2 Magic Byte (0xFD) or v1 (0xFE)
    let magic = pkt.get_u8(0);
    if magic == Some(0xFD) {
        // MAVLink v2: Msg ID is a 24-bit integer at offsets 7, 8, 9
        let msg_id = (pkt.get_u8(7).unwrap_or(0) as u32)
            | ((pkt.get_u8(8).unwrap_or(0) as u32) << 8)
            | ((pkt.get_u8(9).unwrap_or(0) as u32) << 16);

        // Msg ID 76 = COMMAND_LONG
        if msg_id == 76 {
            // Block unauthenticated drone commands
            return Verdict::KernelDrop as i32;
        }
    } else if magic == Some(0xFE) {
        // MAVLink v1: Msg ID is at offset 5
        let msg_id = pkt.get_u8(5).unwrap_or(0);
        if msg_id == 76 {
            return Verdict::KernelDrop as i32;
        }
    }

    Verdict::Pass as i32
}
