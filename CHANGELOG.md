# Changelog

## [Unreleased]

## [2.2.7-2] - 2026-09-26

### Fixed

- The binary quoted directories from the machine that built it — paths under
  `/nix/store` that exist nowhere else. They were never read at runtime, but
  they are gone now, so the binary carries nothing about its build host.

### Changed

- The binary is larger than the previous release (3.1 MB to 5.0 MB). It is
  built by a different compiler now; about a quarter of the growth is a symbol
  table that makes ddcutil's crash reports show function names instead of bare
  addresses. Every feature is unchanged.
