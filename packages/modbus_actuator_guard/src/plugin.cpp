#include <sentinel/sdk/plugin.hpp>

using namespace sentinel::sdk;

static SentinelDissectorResult modbus_dissect(const SentinelRawPacket* raw_pkt) {
    if (!raw_pkt || !raw_pkt->data || raw_pkt->length < 8) {
        return VerdictBuilder::Pass();
    }

    PacketView pkt(*raw_pkt);

    auto proto_id = pkt.read_be16(2);
    if (!proto_id.has_value() || proto_id.value() != 0x0000) {
        return VerdictBuilder::Pass();
    }

    auto fc = pkt.peek_u8(7);
    if (!fc.has_value()) return VerdictBuilder::Pass();

    if (fc.value() == 0x05 || fc.value() == 0x0F) {
        return VerdictBuilder::Drop(1001, "UNAUTHORIZED_MODBUS_COIL_WRITE", 1.0f)
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
    "org.aryorithm.package.modbus_actuator_guard",
    "Modbus SCADA Physical Actuator Guard",
    "1.0.0",
    "MODBUS_TCP",
    502,
    0,
    nullptr,
    nullptr,
    modbus_dissect
};

SENTINEL_REGISTER_PLUGIN(g_descriptor)
