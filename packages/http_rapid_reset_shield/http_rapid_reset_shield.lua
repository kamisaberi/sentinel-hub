local ffi = ffi or require("ffi")

Rule = {
    id   = 5003,
    name = "EXPLOIT_HTTP2_RAPID_RESET_FLOOD",
    port = 443
}

local rst_counter = 0
local window_start_ns = 0
local MAX_RST_PER_SEC = 20

function Rule.inspect(pkt)
    if not pkt or not pkt.data then return 0 end
    local len = tonumber(pkt.length)
    if not len or len < 9 then return 0 end

    -- Scan for HTTP/2 Frame Type 0x03 (RST_STREAM)
    -- Frame header: Length (3B), Type (1B), Flags (1B), Stream ID (4B)
    for i = 0, len - 9 do
        local frame_type = pkt.data[i + 3]
        if frame_type == 3 then -- RST_STREAM
            local now = tonumber(pkt.timestamp_ns)
            if window_start_ns == 0 or (now - window_start_ns) > 1000000000 then
                window_start_ns = now
                rst_counter = 1
            else
                rst_counter = rst_counter + 1
                if rst_counter > MAX_RST_PER_SEC then
                    return 3 -- SENTINEL_VERDICT_KERNEL_DROP
                end
            end
        end
    end

    return 0 -- PASS
end
