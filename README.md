# Asus-Merlin-Zapret2-GUI

A completely modular WebUI Addon for AsusWRT-Merlin to manage the `zapret2` DPI bypass utility by `bol-van`.

## Features
- **Modular Architecture**: Cleanly separated logic into single-purpose POSIX sh modules.
- **Robust Concurrency**: Implements busybox-compatible atomic locks using directory creation to prevent race conditions during configuration changes.
- **Safe Apply & Rollback**: Built-in health-checks. Before applying a new strategy, a backup of the current configuration is made. If `zapret2` fails to start or parameters don't match expectations, the configuration is automatically rolled back.
- **Persistent WebUI**: Survives HTTPD restarts and reboots via `services-start` and `service-event-end` JFFS hooks.
- **Automated Tests**: Includes a mock-based test suite (`tests/test_core.sh`) to verify lock safety, configuration integrity, and rollback mechanics across any POSIX shell environment.

## Installation

Run the following command on your router via SSH:
```sh
curl -L -s https://raw.githubusercontent.com/TABURELTER/Asus-Merlin-Zapret2-GUI/main/install.sh | sh
```

## Architecture
The addon avoids large monolithic shell scripts and instead categorizes behavior:
- `lib/merlin.sh`: Integration with the AsusWRT-Merlin WebUI via `bind-mount` injection.
- `lib/lock.sh`: A `mkdir`-based mutex mechanism with time-to-live detection for stale locks, alongside `Run_With_Timeout`.
- `lib/config.sh`: Safely modifies `/opt/zapret2/config` without using complex string parsing, instead leveraging a dedicated GUI settings block appended dynamically.
- `lib/strategy.sh`: Parses WebUI inputs and constructs the complex `NFQWS2_OPT` block, supporting specific Lua desync strategies (`--lua-desync=fake,multisplit` etc).
- `lib/safe_apply.sh`: Orchestrates the safe modification of settings, process restart, and verification.
- `zapret2-gui.sh`: The dispatcher that bridges WebUI JSON events with backend logic.

### State Modification via WebUI
Due to known bugs in specific AsusWRT-Merlin firmware builds where `httpd` fails to persist custom POST variables (`amng_custom`), this addon uses a modern JSON-to-base64 fetch payload combined with a hidden form `apply.cgi` rc_service trigger.

## Requirements
- AsusWRT-Merlin firmware.
- JFFS custom scripts and configs enabled.
- Entware and `bol-van/zapret2` pre-installed at `/opt/zapret2/`.
