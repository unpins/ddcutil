# ddcutil

[ddcutil](https://www.ddcutil.com/), a program to query and change Linux monitor settings (brightness, contrast, input source, …) over DDC/CI and USB. A single self-contained binary, built natively for Linux.

[![CI](https://github.com/unpins/ddcutil/actions/workflows/ddcutil.yml/badge.svg)](https://github.com/unpins/ddcutil/actions)
![Linux](https://img.shields.io/badge/Linux-✓-success?logo=linux&logoColor=white)

Part of the [unpins](https://unpins.org) catalog; install it with [`unpin`](https://github.com/unpins/unpin): `unpin install ddcutil`.

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

Run `ddcutil` as root, or set up access once so you don't have to:

```bash
sudo groupadd --system i2c                                  # if it doesn't exist yet
sudo usermod -aG i2c "$USER"                                # log out and back in after this
echo i2c-dev | sudo tee /etc/modules-load.d/ddcutil.conf    # load the module at boot
sudo tee /etc/udev/rules.d/60-ddcutil-i2c.rules >/dev/null <<'RULES'
SUBSYSTEM=="i2c-dev", KERNEL=="i2c-[0-9]*", GROUP="i2c", MODE="0660"
SUBSYSTEM=="i2c-dev", KERNEL=="i2c-[0-9]*", ATTRS{class}=="0x03*", TAG+="uaccess"
SUBSYSTEM=="dri", KERNEL=="card[0-9]*", TAG+="uaccess"
RULES
```

These are the files a distribution's ddcutil package installs for you, and a
single binary can't. `ddcutil environment` tells you what is still missing; the
[upstream page](https://www.ddcutil.com/i2c_permissions/) covers the unusual
cases.

To install it onto your PATH:

```bash
unpin install ddcutil
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

## Build notes

- **Linux-only:** no macOS or Windows port (see the kernel-interface note above).
- **Device names in `ddcutil environment`:** the vendor and model names of your
  video card are read from the system's `pci.ids` database (`/usr/share/hwdata`
  on most distributions). Without it that one report shows numeric IDs instead;
  everything else, including talking to monitors, is unaffected.
- **Man page:** embedded in the binary — read it with `unpin man ddcutil`.
- **Tests:** no native suite runs. ddcutil defines no automake `TESTS=` target, so `make check` only *compiles* the libddcutil API sample clients (never runs them); its real testcases need a live monitor on the i2c bus, which CI can't provide. Upstream (and nixpkgs) ship with checks off, and we match.
