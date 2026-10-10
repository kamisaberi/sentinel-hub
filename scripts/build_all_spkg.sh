#!/usr/bin/env bash
set -e

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SPKG_TOOL="/home/kami/blackbox-sentinel/build/sentinel-spkg"
DIST_DIR="${REPO_ROOT}/dist"
KEY_DIR="${REPO_ROOT}/keys"

mkdir -p "$DIST_DIR" "$KEY_DIR"
cd "$REPO_ROOT"

echo "============================================================"
echo "    SENTINEL-HUB: COMPILING & SEALING STARTER .SPKG PACKAGES"
echo "============================================================"

# 1. Ensure Authority Signing Key exists
if [ ! -f "${KEY_DIR}/authority_key_private.pem" ]; then
    echo "[+] Generating official Aryorithm Hub signing authority keypair..."
    "$SPKG_TOOL" keygen "${KEY_DIR}/authority_key"
fi
PRIV_KEY="${KEY_DIR}/authority_key_private.pem"
PUB_KEY="${KEY_DIR}/authority_key_public.pem"

# 2. Compile & Pack Package 1: Modbus C++ Native
echo "[+] Building Package 1: modbus_actuator_guard (Native C++20)..."
(
    cd packages/modbus_actuator_guard
    mkdir -p build && cd build
    cmake .. -DCMAKE_BUILD_TYPE=Release > /dev/null
    make -j"$(nproc)" > /dev/null
)
"$SPKG_TOOL" pack \
    "$PRIV_KEY" \
    0 \
    packages/modbus_actuator_guard/manifest.json \
    packages/modbus_actuator_guard/build/modbus_actuator_guard.so \
    packages/modbus_actuator_guard/src/plugin.cpp \
    packages/modbus_actuator_guard/tests/preflight_frame.bin \
    "${DIST_DIR}/modbus_actuator_guard.spkg"

# 3. Compile & Pack Package 2: S7Comm Rust Wasm
echo "[+] Building Package 2: s7comm_safety_interlock (Rust WebAssembly)..."
(
    cd packages/s7comm_safety_interlock
    cargo build --target wasm32-unknown-unknown --release --quiet
)
"$SPKG_TOOL" pack \
    "$PRIV_KEY" \
    1 \
    packages/s7comm_safety_interlock/manifest.json \
    packages/s7comm_safety_interlock/target/wasm32-unknown-unknown/release/s7comm_safety_interlock.wasm \
    packages/s7comm_safety_interlock/src/lib.rs \
    packages/s7comm_safety_interlock/tests/preflight_frame.bin \
    "${DIST_DIR}/s7comm_safety_interlock.spkg"

# 4. Pack Package 3: Log4j Lua Dynamic Rule
echo "[+] Packing Package 3: log4j_jndi_fastdrop (LuaJIT Dynamic)..."
"$SPKG_TOOL" pack \
    "$PRIV_KEY" \
    2 \
    packages/log4j_jndi_fastdrop/manifest.json \
    packages/log4j_jndi_fastdrop/log4j_jndi_fastdrop.lua \
    packages/log4j_jndi_fastdrop/log4j_jndi_fastdrop.lua \
    packages/log4j_jndi_fastdrop/tests/preflight_frame.bin \
    "${DIST_DIR}/log4j_jndi_fastdrop.spkg"

# 5. Verify all generated packages
echo "------------------------------------------------------------"
echo "[+] Cryptographically verifying output .spkg files in dist/..."
for pkg in "${DIST_DIR}"/*.spkg; do
    echo "Verifying $(basename "$pkg")..."
    "$SPKG_TOOL" verify "$PUB_KEY" "$pkg"
done

echo "============================================================"
echo " [SUCCESS] All 3 Starter Packages Built & Sealed in dist/! "
ls -lh "$DIST_DIR"
echo "============================================================"
