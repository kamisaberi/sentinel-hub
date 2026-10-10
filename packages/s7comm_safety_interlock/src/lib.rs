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

    if pkt.len() < 18 {
        return Verdict::Pass as i32;
    }

    // Byte 0: TPKT Header (0x03)
    // Byte 7: S7 Protocol Identifier (0x32 = Siemens S7Comm)
    if pkt.get_u8(0) == Some(0x03) && pkt.get_u8(7) == Some(0x32) {
        let msg_type = pkt.get_u8(9);
        let func_code = pkt.get_u8(17);

        // Job Request (0x01) with Function 0x29 (CPU STOP Command)
        if msg_type == Some(0x01) && func_code == Some(0x29) {
            return Verdict::KernelDrop as i32;
        }
    }

    Verdict::Pass as i32
}
