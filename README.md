# Sentinel-Hub: The Official Aryorithm Package Registry

Official community and certified industrial `.spkg` (Sentinel Package) extensions for **Blackbox Sentinel**.

## Certified Starter Packages

| Package | Tier | Protocol | Latency SLA | Description |
| :--- | :--- | :--- | :--- | :--- |
| **`modbus_actuator_guard.spkg`** | Native C++20 | Modbus TCP | `< 120 ns` | Sub-microsecond coil override and actuator valve clamp |
| **`s7comm_safety_interlock.spkg`** | Rust Wasm3 | Siemens S7 | `< 1.5 µs` | Memory-sandboxed S7 PLC CPU Stop command blocker |
| **`log4j_jndi_fastdrop.spkg`** | LuaJIT FFI | Raw TCP/HTTP | `< 450 ns` | Zero-allocation sliding scanner for JNDI exploits |

## How to Install on Appliances

Using the Sentinel Nexus CLI:
```bash
nexus-ctl hub broadcast dist/modbus_actuator_guard.spkg
Inspecting a package:
code
Bash
sentinel-spkg inspect dist/modbus_actuator_guard.spkg
