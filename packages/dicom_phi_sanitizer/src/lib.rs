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
    if pkt.len() < 132 {
        return Verdict::Pass as i32;
    }
    if pkt.get_u8(128) == Some(b'D')
        && pkt.get_u8(129) == Some(b'I')
        && pkt.get_u8(130) == Some(b'C')
        && pkt.get_u8(131) == Some(b'M')
    {
        for i in 132..pkt.len() - 4 {
            if pkt.get_u8(i) == Some(0x10)
                && pkt.get_u8(i + 1) == Some(0x00)
                && (pkt.get_u8(i + 2) == Some(0x10) || pkt.get_u8(i + 2) == Some(0x20))
                && pkt.get_u8(i + 3) == Some(0x00)
            {
                return Verdict::KernelDrop as i32;
            }
        }
    }
    Verdict::Pass as i32
}
