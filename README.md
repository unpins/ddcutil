# ddcutil

Standalone build of [ddcutil](https://www.ddcutil.com/), a tool to query and change Linux monitor settings (brightness, contrast, input source, …) over DDC/CI and USB.

[![CI](https://github.com/unpins/ddcutil/actions/workflows/ddcutil.yml/badge.svg)](https://github.com/unpins/ddcutil/actions)
![Linux](https://img.shields.io/badge/Linux-✓-success?logo=linux&logoColor=white)

Part of the [unpins](https://unpins.org) project — native single-binary builds with no third-party runtime dependencies.

Linux-only: ddcutil drives external monitors through the `i2c-dev` kernel interface and enumerates devices via `libudev`/`sysfs`, both kernel-locked.

## Usage

ddcutil talks to monitors over the I²C bus, which needs the `i2c-dev` kernel module loaded and read/write access to `/dev/i2c-*`:

```bash
sudo modprobe i2c-dev
ddcutil detect                 # list monitors reachable over DDC/CI
ddcutil getvcp 10              # read brightness (VCP feature 0x10)
ddcutil setvcp 10 50           # set brightness to 50%
ddcutil capabilities           # dump the monitor's DDC capability string
ddcutil environment            # probe the runtime environment (no monitor needed)
```

Run `ddcutil` as root, or add your user to the `i2c` group and install the udev rules from the [upstream docs](https://www.ddcutil.com/i2c_permissions/).

## Installation

Install with [unpin](https://github.com/unpins/unpin):

```bash
unpin ddcutil
```

Or run without installing:

```bash
unpin run ddcutil
```

## Build locally

```bash
nix build github:unpins/ddcutil
./result/bin/ddcutil --version
```

Or run directly:

```bash
nix run github:unpins/ddcutil -- detect
```

The first invocation will offer to add the [unpins.cachix.org](https://unpins.cachix.org) substituter so most pulls come pre-built.

## Manual download

The [Releases](https://github.com/unpins/ddcutil/releases) page has standalone binaries for manual download.
