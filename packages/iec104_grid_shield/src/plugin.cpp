#include <sentinel/sdk/plugin.hpp>

using namespace sentinel::sdk;

static SentinelDissectorResult iec104_dissect(const SentinelRawPacket* raw_pkt) {
    if (!raw_pkt || !raw_pkt->data || raw_pkt->length < 15) {
        return VerdictBuilder::Pass();
    }

    PacketView pkt(*raw_pkt);

    // IEC-104 APCI Start Byte must be 0x68
    if (pkt.peek_u8(0) != 0x68) {
        return VerdictBuilder::Pass();
    }

    // Offset 6: ASDU Type ID
    // Type 45 (0x2D) = C_SC_NA_1 (Single Command)
    // Type 46 (0x2E) = C_DC_NA_1 (Double Command)
    auto asdu_type = pkt.peek_u8(6);
    if (asdu_type == 0x2D || asdu_type == 0x2E) {
        // Offset 14/15: Command Qualifier (0x01 = Execute / Trip Breaker)
        auto cmd_state = pkt.peek_u8(raw_pkt->length - 1);
        if (cmd_state.has_value() && (cmd_state.value() & 0x01) == 0x01) {
            return VerdictBuilder::Drop(2001, "ROGUE_IEC104_BREAKER_TRIP_COMMAND", 1.0f)
                .with_tag(tags::CPS_ACTUATOR_WRITE)
                .with_tag(tags::CPS_SAFETY_INTERLOCK_BYPASS)
                .build();
        }
    }

    return VerdictBuilder::Pass();
}

static SentinelPluginDescriptor g_descriptor = {
    SENTINEL_SDK_MAGIC,
    SENTINEL_SDK_VERSION_MAJOR,
    SENTINEL_SDK_VERSION_MINOR,
    SENTINEL_TIER_NATIVE_CPP,
    "org.aryorithm.package.iec104_grid_shield",
    "IEC-104 High-Voltage Grid Telecontrol Shield",
    "1.0.0",
    "IEC_60870_5_104",
    2404,
    0,
    nullptr,
    nullptr,
    iec104_dissect
};

SENTINEL_REGISTER_PLUGIN(g_descriptor)
