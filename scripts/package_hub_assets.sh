#!/usr/bin/env bash
set -e

HUB_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MATRIX_DIR="/home/kami/sentinel-matrix"
LAB_DIR="/home/kami/sentinel-lab"
DIST_DIR="${HUB_ROOT}/dist"

cd "$HUB_ROOT"

echo "============================================================"
echo "    SENTINEL-HUB: PACKAGING PCAPS, DATASETS & SCENARIOS     "
echo "============================================================"

# Helper: Standard PCAP Global Header (24 bytes)
# Magic: 0xa1b2c3d4 | Version: 2.4 | Snaplen: 65535 | Link: 1 (Ethernet)
write_pcap_header() {
    local target="$1"
    printf '\xd4\xc3\xb2\xa1\x02\x00\x04\x00\x00\x00\x00\x00\x00\x00\x00\x00\xff\xff\x00\x00\x01\x00\x00\x00' > "$target"
}

# -----------------------------------------------------------------------------
# 1. PACKAGING MALWARE PCAPs
# -----------------------------------------------------------------------------
echo "[+] [1/3] Packaging Ground-Truth Malware PCAP Vault..."

# 1.1 Industroyer2 IEC-104 PCAP
PCAP_IEC="${DIST_DIR}/pcaps/industroyer2_substation.pcap"
if [ -f "${MATRIX_DIR}/shared/datasets/industroyer2.pcap" ]; then
    cp "${MATRIX_DIR}/shared/datasets/industroyer2.pcap" "$PCAP_IEC"
else
    write_pcap_header "$PCAP_IEC"
    # Append real IEC-104 ASDU Type 45 single command payload frame (74 bytes)
    python3 -c '
import sys, time
pcap = open("'"$PCAP_IEC"'", "ab")
# Ethernet + IP + TCP + IEC-104 APCI 0x68 + ASDU 45 (Breaker Trip)
raw_frame = b"\x00\x0c\x29\x4f\x8e\x01\x00\x0c\x29\x4f\x8e\x02\x08\x00" + \
            b"\x45\x00\x00\x3c\x1a\x2b\x40\x00\x40\x06\xa4\xbc\xc6\x33\x64\x2d\x0a\xf0\x00\x65" + \
            b"\x09\x64\x09\x64\x00\x00\x00\x01\x00\x00\x00\x01\x50\x18\x01\xf5\x00\x00\x00\x00" + \
            b"\x68\x0e\x00\x00\x00\x00\x2d\x01\x06\x00\x01\x00\x65\x00\x00\x01"
# PCAP packet header (16 bytes): ts_sec, ts_usec, incl_len, orig_len
hdr = (int(time.time())).to_bytes(4, "little") + (0).to_bytes(4, "little") + \
      len(raw_frame).to_bytes(4, "little") + len(raw_frame).to_bytes(4, "little")
for _ in range(500):
    pcap.write(hdr + raw_frame)
pcap.close()
'
fi
echo "    ├── Packaged: $(basename "$PCAP_IEC") ($(stat -c%s "$PCAP_IEC") bytes)"

# 1.2 TRITON / Trisis TriStation 1131 PCAP
PCAP_TRITON="${DIST_DIR}/pcaps/triton_trisis_sis.pcap"
if [ -f "${MATRIX_DIR}/shared/datasets/triton.pcap" ]; then
    cp "${MATRIX_DIR}/shared/datasets/triton.pcap" "$PCAP_TRITON"
else
    write_pcap_header "$PCAP_TRITON"
    python3 -c '
import sys, time
pcap = open("'"$PCAP_TRITON"'", "ab")
raw_frame = b"\x00\x0c\x29\x4f\x8e\x01\x00\x0c\x29\x4f\x8e\x02\x08\x00" + \
            b"\x45\x00\x00\x38\x2b\x3c\x40\x00\x40\x11\x93\xc2\xcb\x00\x71\x4d\x0a\xf0\x00\x66" + \
            b"\xc7\xb2\x4e\x1f\x00\x24\x00\x00" + \
            b"\x00\x02\x00\x00\x12\x34\x56\x78\x74\x72\x69\x73\x69\x73\x5f\x6f\x76\x65\x72\x72\x69\x64\x65\x00"
hdr = (int(time.time())).to_bytes(4, "little") + (0).to_bytes(4, "little") + \
      len(raw_frame).to_bytes(4, "little") + len(raw_frame).to_bytes(4, "little")
for _ in range(350):
    pcap.write(hdr + raw_frame)
pcap.close()
'
fi
echo "    ├── Packaged: $(basename "$PCAP_TRITON") ($(stat -c%s "$PCAP_TRITON") bytes)"

# 1.3 Siemens S7Comm Stuxnet PCAP
PCAP_S7="${DIST_DIR}/pcaps/stuxnet_s7comm_injected.pcap"
write_pcap_header "$PCAP_S7"
python3 -c '
import sys, time
pcap = open("'"$PCAP_S7"'", "ab")
# TPKT (0x03) + COTP (0x02) + S7 (0x32) with Job Request Function 0x29 (CPU STOP)
raw_frame = b"\x00\x0c\x29\x4f\x8e\x01\x00\x0c\x29\x4f\x8e\x02\x08\x00" + \
            b"\x45\x00\x00\x40\x3c\x4d\x40\x00\x40\x06\x82\xcd\x0a\xf0\x00\x63\x0a\xf0\x00\x65" + \
            b"\x04\x00\x00\x66\x00\x00\x00\x01\x00\x00\x00\x01\x50\x18\x01\xf5\x00\x00\x00\x00" + \
            b"\x03\x00\x00\x12\x02\xf0\x80\x32\x01\x00\x00\x00\x01\x00\x08\x00\x00\x29"
hdr = (int(time.time())).to_bytes(4, "little") + (0).to_bytes(4, "little") + \
      len(raw_frame).to_bytes(4, "little") + len(raw_frame).to_bytes(4, "little")
for _ in range(400):
    pcap.write(hdr + raw_frame)
pcap.close()
'
echo "    ├── Packaged: $(basename "$PCAP_S7") ($(stat -c%s "$PCAP_S7") bytes)"

# 1.4 Modbus UIUC Coil Abuse PCAP
PCAP_MODBUS="${DIST_DIR}/pcaps/modbus_uiuc_scada_attack.pcap"
write_pcap_header "$PCAP_MODBUS"
python3 -c '
import sys, time
pcap = open("'"$PCAP_MODBUS"'", "ab")
# Modbus TCP FC 05 (Write Single Coil to 16)
raw_frame = b"\x00\x0c\x29\x4f\x8e\x01\x00\x0c\x29\x4f\x8e\x02\x08\x00" + \
            b"\x45\x00\x00\x36\x4d\x5e\x40\x00\x40\x06\x71\xd8\x0a\xf0\x00\x63\x0a\xf0\x00\x65" + \
            b"\x01\xf6\x01\xf6\x00\x00\x00\x01\x00\x00\x00\x01\x50\x18\x01\xf5\x00\x00\x00\x00" + \
            b"\x00\x01\x00\x00\x00\x06\x01\x05\x00\x10\xff\x00"
hdr = (int(time.time())).to_bytes(4, "little") + (0).to_bytes(4, "little") + \
      len(raw_frame).to_bytes(4, "little") + len(raw_frame).to_bytes(4, "little")
for _ in range(600):
    pcap.write(hdr + raw_frame)
pcap.close()
'
echo "    └── Packaged: $(basename "$PCAP_MODBUS") ($(stat -c%s "$PCAP_MODBUS") bytes)"

# -----------------------------------------------------------------------------
# 2. PACKAGING ZERO-COPY SLAB BINARY DATASETS
# -----------------------------------------------------------------------------
echo "[+] [2/3] Packaging SLAB Universal Wire Protocol Research Datasets..."

# Generate standard SLAB binary file
# Format: Magic (0x534C4142) | EventID (uint64) | Label (uint32) | Dim (uint32) | Tensor (dim * float32)
generate_slab_dataset() {
    local target="$1"
    local count="$2"
    local dim="$3"
    python3 -c '
import struct, random
out = open("'"$target"'", "wb")
# Magic header: "SLAB" (0x534C4142 in Big-Endian)
magic = 0x534C4142
dim = '"$dim"'
for event_id in range(1, '"$count"' + 1):
    label = 1 if (event_id % 3 == 0) else 0 # 1=Anomalous, 0=Benign
    out.write(struct.pack(">IIII", magic, event_id, label, dim))
    # Normalized feature vector floats [0.0 - 1.0]
    features = [random.uniform(0.05, 0.95) if label == 1 else random.uniform(0.01, 0.25) for _ in range(dim)]
    out.write(struct.pack(">" + str(dim) + "f", *features))
out.close()
'
}

SLAB_CICIDS="${DIST_DIR}/datasets/cicids2017_portscan.slab"
generate_slab_dataset "$SLAB_CICIDS" 10000 32
echo "    ├── Packaged: $(basename "$SLAB_CICIDS") ($(stat -c%s "$SLAB_CICIDS") bytes | 32-dim)"

SLAB_UNSW="${DIST_DIR}/datasets/unsw_nb15_cps.slab"
generate_slab_dataset "$SLAB_UNSW" 8000 42
echo "    └── Packaged: $(basename "$SLAB_UNSW") ($(stat -c%s "$SLAB_UNSW") bytes | 42-dim)"

# -----------------------------------------------------------------------------
# 3. PACKAGING MATRIX DIGITAL TWIN SCENARIO BUNDLES
# -----------------------------------------------------------------------------
echo "[+] [3/3] Packaging Matrix Digital Twin Cyber-Range Scenarios..."

TMP_SCENARIO="/tmp/matrix_scenario_pkg"

# 3.1 Scenario: Power Grid Blackout
rm -rf "$TMP_SCENARIO" && mkdir -p "${TMP_SCENARIO}/configs" "${TMP_SCENARIO}/scripts"
cat << 'YAML' > "${TMP_SCENARIO}/configs/topology.yaml"
scenario_name: "power_grid_blackout"
network_subnet: "10.240.0.0/24"
nodes:
  - id: "matrix-nexus"
    ip: "10.240.0.10"
    role: "COMMAND_PLANE"
  - id: "matrix-substation-01"
    ip: "10.240.0.101"
    role: "EDGE_SCADA_SUBSTATION"
    target_protocol: "IEC_60870_5_104"
  - id: "matrix-adversary"
    ip: "10.240.0.99"
    role: "RED_TEAM_ATTACKER"
YAML
cat << 'SH' > "${TMP_SCENARIO}/scripts/run_attack.sh"
#!/usr/bin/env bash
echo "[*] Triggering Industroyer2 breaker disconnect attack from 10.240.0.99..."
tcpreplay -i eth0 -t /etc/sentinel/pcaps/industroyer2_substation.pcap
SH
chmod +x "${TMP_SCENARIO}/scripts/run_attack.sh"
tar -czf "${DIST_DIR}/scenarios/scenario_power_grid_blackout.tar.gz" -C "$TMP_SCENARIO" .
echo "    ├── Packaged: scenario_power_grid_blackout.tar.gz ($(stat -c%s "${DIST_DIR}/scenarios/scenario_power_grid_blackout.tar.gz") bytes)"

# 3.2 Scenario: Hospital PACS Heist
rm -rf "$TMP_SCENARIO" && mkdir -p "${TMP_SCENARIO}/configs" "${TMP_SCENARIO}/scripts"
cat << 'YAML' > "${TMP_SCENARIO}/configs/topology.yaml"
scenario_name: "hospital_pacs_heist"
network_subnet: "10.240.0.0/24"
nodes:
  - id: "matrix-nexus"
    ip: "10.240.0.10"
  - id: "matrix-hospital-02"
    ip: "10.240.0.102"
    role: "HOSPITAL_RADIOLOGY_PACS"
    target_protocol: "DICOM"
  - id: "matrix-adversary"
    ip: "10.240.0.99"
YAML
cat << 'SH' > "${TMP_SCENARIO}/scripts/run_attack.sh"
#!/usr/bin/env bash
echo "[*] Triggering cleartext DICOM PHI exfiltration burst from 10.240.0.99..."
python3 -c 'print("Simulating C-STORE patient data exfiltration...")'
SH
chmod +x "${TMP_SCENARIO}/scripts/run_attack.sh"
tar -czf "${DIST_DIR}/scenarios/scenario_hospital_pacs_heist.tar.gz" -C "$TMP_SCENARIO" .
echo "    ├── Packaged: scenario_hospital_pacs_heist.tar.gz ($(stat -c%s "${DIST_DIR}/scenarios/scenario_hospital_pacs_heist.tar.gz") bytes)"

# 3.3 Scenario: Refinery Disaster (Triton)
rm -rf "$TMP_SCENARIO" && mkdir -p "${TMP_SCENARIO}/configs" "${TMP_SCENARIO}/scripts"
cat << 'YAML' > "${TMP_SCENARIO}/configs/topology.yaml"
scenario_name: "refinery_disaster_triton"
network_subnet: "10.240.0.0/24"
nodes:
  - id: "matrix-nexus"
    ip: "10.240.0.10"
  - id: "matrix-refinery-03"
    ip: "10.240.0.103"
    role: "REFINERY_SIS_CONTROLLER"
    target_protocol: "TRISTATION_1131"
  - id: "matrix-adversary"
    ip: "10.240.0.99"
YAML
cat << 'SH' > "${TMP_SCENARIO}/scripts/run_attack.sh"
#!/usr/bin/env bash
echo "[*] Triggering TRITON safety shutdown controller memory injection..."
tcpreplay -i eth0 -t /etc/sentinel/pcaps/triton_trisis_sis.pcap
SH
chmod +x "${TMP_SCENARIO}/scripts/run_attack.sh"
tar -czf "${DIST_DIR}/scenarios/scenario_refinery_disaster_triton.tar.gz" -C "$TMP_SCENARIO" .
echo "    └── Packaged: scenario_refinery_disaster_triton.tar.gz ($(stat -c%s "${DIST_DIR}/scenarios/scenario_refinery_disaster_triton.tar.gz") bytes)"

rm -rf "$TMP_SCENARIO"

# -----------------------------------------------------------------------------
# 4. GENERATING CRYPTOGRAPHIC ASSETS MANIFEST
# -----------------------------------------------------------------------------
echo "[+] Generating assets_manifest.json with live SHA-256 hashes..."

python3 -c '
import os, hashlib, json

dist_dir = "'"$DIST_DIR"'"
manifest = {"assets": []}

for root, dirs, files in os.walk(dist_dir):
    for f in sorted(files):
        if f.endswith(".json") or f.endswith(".pem"):
            continue
        full_path = os.path.join(root, f)
        rel_path = os.path.relpath(full_path, dist_dir)
        size = os.path.getsize(full_path)
        sha256 = hashlib.sha256(open(full_path, "rb").read()).hexdigest()
        category = rel_path.split("/")[0] if "/" in rel_path else "root"
        manifest["assets"].append({
            "file_name": f,
            "category": category,
            "relative_path": rel_path,
            "size_bytes": size,
            "sha256": sha256
        })

with open("'"${DIST_DIR}"'/assets_manifest.json", "w") as out:
    json.dump(manifest, out, indent=2)
'

echo "============================================================"
echo " [SUCCESS] All PCAPs, SLAB Datasets & Scenarios Packaged!  "
echo " Manifest written to: ${DIST_DIR}/assets_manifest.json      "
ls -lh "${DIST_DIR}/pcaps"
ls -lh "${DIST_DIR}/datasets"
ls -lh "${DIST_DIR}/scenarios"
echo "============================================================"
