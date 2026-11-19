#!/usr/bin/env bash
# Copyright 2026 Cloudsmith Ltd
# Fails when src/scripts/install.sh does not match the checksum in
# src/scripts/install.sh.version. Update both files together when you vendor a
# new installer release.
set -euo pipefail

expected="$(awk -F= '$1 == "sha256" {print $2}' src/scripts/install.sh.version)"
actual="$(sha256sum src/scripts/install.sh | awk '{print $1}')"
if [[ "$expected" != "$actual" ]]; then
  echo "src/scripts/install.sh does not match src/scripts/install.sh.version" >&2
  echo "expected sha256: $expected" >&2
  echo "actual sha256:   $actual" >&2
  echo "Update both files together when vendoring a new installer release." >&2
  exit 1
fi
version="$(awk -F= '$1 == "version" {print $2}' src/scripts/install.sh.version)"
echo "Vendored installer (version: $version) matches the recorded checksum."
