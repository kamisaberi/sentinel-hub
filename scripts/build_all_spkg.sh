#!/usr/bin/env bash
set -e

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SPKG_TOOL="/home/kami/blackbox-sentinel/build/sentinel-spkg"
DIST_DIR="${REPO_ROOT}/dist"
KEY_DIR="${REPO_ROOT}/keys"

mkdir -p "$DIST_DIR" "$KEY_DIR"
cd "$REPO_ROOT"

echo "============================================================"
echo "    SENTINEL-HUB: COMPILING & SEALING THE ENTIRE CORE 8     "
echo "============================================================"

# Ensure Authority Signing Key exists
if [ ! -f "${KEY_DIR}/authority_key_private.pem" ]; then
    echo "[+] Generating official Aryorithm Hub signing authority keypair..."
    "$SPKG_TOOL" keygen "${KEY_DIR}/authority_key"
fi
PRIV_KEY="${KEY_DIR}/authority_key_private.pem"
PUB_KEY="${KEY_DIR}/authority_key_public.pem"

# 1. Modbus C++ Native
echo "[+] 1/8: modbus_actuator_guard (Native C++20)..."
(
    cd packages/modbus_actuator_guard
    mkdir -p build && cd build
    cmake .. -DCMAKE_BUILD_TYPE=Release > /dev/null
    make -j"$(nproc)" > /dev/null
)
"$SPKG_TOOL" pack "$PRIV_KEY" 0 \
    packages/modbus_actuator_guard/manifest.json \
    packages/modbus_actuator_guard/build/modbus_actuator_guard.so \
    packages/modbus_actuator_guard/src/plugin.cpp \
    packages/modbus_actuator_guard/tests/preflight_frame.bin \
    "${DIST_DIR}/modbus_actuator_guard.spkg"

# 2. S7Comm Rust Wasm
echo "[+] 2/8: s7comm_safety_interlock (Rust WebAssembly)..."
(
    cd packages/s7comm_safety_interlock
    cargo build --target wasm32-unknown-unknown --release --quiet
)
"$SPKG_TOOL" pack "$PRIV_KEY" 1 \
    packages/s7comm_safety_interlock/manifest.json \
    packages/s7comm_safety_interlock/target/wasm32-unknown-unknown/release/s7comm_safety_interlock.wasm \
    packages/s7comm_safety_interlock/src/lib.rs \
    packages/s7comm_safety_interlock/tests/preflight_frame.bin \
    "${DIST_DIR}/s7comm_safety_interlock.spkg"

# 3. Log4j Lua Dynamic
echo "[+] 3/8: log4j_jndi_fastdrop (LuaJIT Dynamic)..."
"$SPKG_TOOL" pack "$PRIV_KEY" 2 \
    packages/log4j_jndi_fastdrop/manifest.json \
    packages/log4j_jndi_fastdrop/log4j_jndi_fastdrop.lua \
    packages/log4j_jndi_fastdrop/log4j_jndi_fastdrop.lua \
    packages/log4j_jndi_fastdrop/tests/preflight_frame.bin \
    "${DIST_DIR}/log4j_jndi_fastdrop.spkg"

# 4. IEC-104 C++ Native
echo "[+] 4/8: iec104_grid_shield (Native C++20)..."
(
    cd packages/iec104_grid_shield
    mkdir -p build && cd build
    cmake .. -DCMAKE_BUILD_TYPE=Release > /dev/null
    make -j"$(nproc)" > /dev/null
)
"$SPKG_TOOL" pack "$PRIV_KEY" 0 \
    packages/iec104_grid_shield/manifest.json \
    packages/iec104_grid_shield/build/iec104_grid_shield.so \
    packages/iec104_grid_shield/src/plugin.cpp \
    packages/iec104_grid_shield/tests/preflight_frame.bin \
    "${DIST_DIR}/iec104_grid_shield.spkg"

# 5. HTTP/2 Rapid Reset Lua Dynamic
echo "[+] 5/8: http_rapid_reset_shield (LuaJIT Dynamic)..."
"$SPKG_TOOL" pack "$PRIV_KEY" 2 \
    packages/http_rapid_reset_shield/manifest.json \
    packages/http_rapid_reset_shield/http_rapid_reset_shield.lua \
    packages/http_rapid_reset_shield/http_rapid_reset_shield.lua \
    packages/http_rapid_reset_shield/tests/preflight_frame.bin \
    "${DIST_DIR}/http_rapid_reset_shield.spkg"

# 6. DICOM Rust Wasm
echo "[+] 6/8: dicom_phi_sanitizer (Rust WebAssembly)..."
(
    cd packages/dicom_phi_sanitizer
    cargo build --target wasm32-unknown-unknown --release --quiet
)
"$SPKG_TOOL" pack "$PRIV_KEY" 1 \
    packages/dicom_phi_sanitizer/manifest.json \
    packages/dicom_phi_sanitizer/target/wasm32-unknown-unknown/release/dicom_phi_sanitizer.wasm \
    packages/dicom_phi_sanitizer/src/lib.rs \
    packages/dicom_phi_sanitizer/tests/preflight_frame.bin \
    "${DIST_DIR}/dicom_phi_sanitizer.spkg"

# 7. DNP3 C++ Native
echo "[+] 7/8: dnp3_water_telemetry (Native C++20)..."
(
    cd packages/dnp3_water_telemetry
    mkdir -p build && cd build
    cmake .. -DCMAKE_BUILD_TYPE=Release > /dev/null
    make -j"$(nproc)" > /dev/null
)
"$SPKG_TOOL" pack "$PRIV_KEY" 0 \
    packages/dnp3_water_telemetry/manifest.json \
    packages/dnp3_water_telemetry/build/dnp3_water_telemetry.so \
    packages/dnp3_water_telemetry/src/plugin.cpp \
    packages/dnp3_water_telemetry/tests/preflight_frame.bin \
    "${DIST_DIR}/dnp3_water_telemetry.spkg"

# 8. MAVLink Rust Wasm
echo "[+] 8/8: mavlink_uav_guardian (Rust WebAssembly)..."
(
    cd packages/mavlink_uav_guardian
    cargo build --target wasm32-unknown-unknown --release --quiet
)
"$SPKG_TOOL" pack "$PRIV_KEY" 1 \
    packages/mavlink_uav_guardian/manifest.json \
    packages/mavlink_uav_guardian/target/wasm32-unknown-unknown/release/mavlink_uav_guardian.wasm \
    packages/mavlink_uav_guardian/src/lib.rs \
    packages/mavlink_uav_guardian/tests/preflight_frame.bin \
    "${DIST_DIR}/mavlink_uav_guardian.spkg"

echo "------------------------------------------------------------"
echo "[+] Cryptographically verifying all 8 .spkg files in dist/..."
for pkg in "${DIST_DIR}"/*.spkg; do
    printf "Verifying %-32s -> " "$(basename "$pkg")"
    "$SPKG_TOOL" verify "$PUB_KEY" "$pkg" | grep VERIFIED
done

echo "============================================================"
echo " [SUCCESS] All 8 Official Core Packages Sealed in dist/!    "
ls -lh "$DIST_DIR"
echo "============================================================"
