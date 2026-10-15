#include <sentinel/sdk/plugin.hpp>

using namespace sentinel::sdk;

static SentinelDissectorResult dnp3_dissect(const SentinelRawPacket* raw_pkt) {
    if (!raw_pkt || !raw_pkt->data || raw_pkt->length < 13) {
        return VerdictBuilder::Pass();
    }

    PacketView pkt(*raw_pkt);

    if (pkt.peek_u8(0) != 0x05 || pkt.peek_u8(1) != 0x64) {
        return VerdictBuilder::Pass();
    }

    auto func_code = pkt.peek_u8(12);
    if (func_code == 0x05 || func_code == 0x06 || func_code == 0x0E) {
        return VerdictBuilder::Drop(3001, "UNAUTHORIZED_DNP3_CHEMICAL_OVERRIDE", 1.0f)
            .with_tag(tags::CPS_ACTUATOR_WRITE)
            .with_tag(tags::CPS_SAFETY_INTERLOCK_BYPASS)
            .build();
    }

    return VerdictBuilder::Pass();
}

static SentinelPluginDescriptor g_descriptor = {
    SENTINEL_SDK_MAGIC,
    SENTINEL_SDK_VERSION_MAJOR,
    SENTINEL_SDK_VERSION_MINOR,
    SENTINEL_TIER_NATIVE_CPP,
    "org.aryorithm.package.dnp3_water_telemetry",
    "DNP3 Municipal Water Chemical Safety Clamp",
    "1.0.0",
    "DNP3",
    20000,
    0,
    nullptr,
    nullptr,
    dnp3_dissect
};

SENTINEL_REGISTER_PLUGIN(g_descriptor)
