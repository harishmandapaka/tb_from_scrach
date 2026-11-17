#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# One-time setup. Everything it downloads is public and goes into third_party/
# (git-ignored). Nothing is installed system-wide and nothing needs sudo.
#   * Accellera UVM reference library (IEEE 1800.2) from accellera.org
#   * Verilator from github.com/verilator/verilator (only with --build-verilator)
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: bash scripts/setup.sh [--build-verilator] [--force-uvm]
  (no option)        download the UVM library and list the simulators found
  --build-verilator  also build the latest Verilator into third_party/verilator
  --force-uvm        download the UVM library again (for example after changing UVM_VER)
Environment:
  UVM_VER        1800.2-2020.3.1 (default) or 1800.2-2017-1.0
  VERILATOR_REF  master (default, as in the Antmicro UVM example), stable, or a release tag
USAGE
}

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TP="$ROOT/third_party"
UVM_VER="${UVM_VER:-1800.2-2020.3.1}"
VERILATOR_REF="${VERILATOR_REF:-master}"
BUILD_VERILATOR=0
FORCE_UVM=0

for arg in "$@"; do
  case "$arg" in
    --build-verilator) BUILD_VERILATOR=1 ;;
    --force-uvm)       FORCE_UVM=1 ;;
    -h|--help)         usage; exit 0 ;;
    *) echo "ERROR: unknown option '$arg'" >&2; usage; exit 2 ;;
  esac
done

case "$UVM_VER" in
  1800.2-2020.3.1) UVM_FILE="${UVM_FILE:-UVM-1800.2-2020.3.1.tar.gz}" ;;
  1800.2-2017-1.0) UVM_FILE="${UVM_FILE:-Accellera-1800.2-2017-1.0.tar.gz}" ;;
  *)
    if [ -z "${UVM_FILE:-}" ]; then
      echo "ERROR: unknown UVM_VER '$UVM_VER'; also set UVM_FILE to the Accellera tarball name." >&2
      exit 2
    fi
    ;;
esac
UVM_URL="${UVM_URL:-https://www.accellera.org/images/downloads/standards/uvm/$UVM_FILE}"

have() { command -v "$1" >/dev/null 2>&1; }
ncpu() { nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 2; }
fetch() {   # fetch URL FILE
  if have curl; then
    curl -fL --retry 3 -o "$2" "$1"
  elif have wget; then
    wget -O "$2" "$1"
  else
    echo "ERROR: curl or wget is needed to download $1" >&2
    exit 2
  fi
}

mkdir -p "$TP"

# 1. Optional: build Verilator into third_party/verilator -----------------------
if [ "$BUILD_VERILATOR" = 1 ]; then
  missing=()
  for t in git autoconf make g++ flex bison perl python3 help2man z3; do
    if ! have "$t"; then missing+=("$t"); fi
  done
  if [ "${#missing[@]}" -gt 0 ]; then
    echo "ERROR: missing tools for building Verilator: ${missing[*]}" >&2
    echo "On Ubuntu, Debian or WSL:" >&2
    echo "  sudo apt-get install -y git autoconf make g++ perl python3 bison flex libfl-dev help2man z3" >&2
    exit 2
  fi
  unset VERILATOR_ROOT
  rm -rf "$TP/verilator-src" "$TP/verilator"
  echo "== Building Verilator ($VERILATOR_REF) into third_party/verilator; this takes a while =="
  git clone --depth 1 --branch "$VERILATOR_REF" https://github.com/verilator/verilator "$TP/verilator-src"
  ( cd "$TP/verilator-src" \
      && autoconf \
      && ./configure --prefix="$TP/verilator" \
      && make -j "$(ncpu)" \
      && make install )
  rm -rf "$TP/verilator-src"
fi

if [ -x "$TP/verilator/bin/verilator" ]; then
  export PATH="$TP/verilator/bin:$PATH"
fi

# 2. UVM library -------------------------------------------------------------------
if [ "$FORCE_UVM" = 1 ]; then
  rm -rf "$TP/uvm"
fi
if [ -f "$TP/uvm/src/uvm_pkg.sv" ]; then
  echo "== UVM already in third_party/uvm ($(cat "$TP/uvm/.uvm_version" 2>/dev/null || echo "version unknown")) =="
else
  echo "== Downloading UVM $UVM_VER from $UVM_URL =="
  tmp="$TP/.uvm_download"
  rm -rf "$tmp"
  mkdir -p "$tmp"
  fetch "$UVM_URL" "$tmp/uvm.tar.gz"
  tar -xzf "$tmp/uvm.tar.gz" -C "$tmp"
  set -- "$tmp"/*/src/uvm_pkg.sv
  if [ ! -f "$1" ]; then
    echo "ERROR: the download does not contain <folder>/src/uvm_pkg.sv" >&2
    exit 1
  fi
  mv "$(dirname "$(dirname "$1")")" "$TP/uvm"
  echo "$UVM_VER" > "$TP/uvm/.uvm_version"
  rm -rf "$tmp"
  echo "UVM $UVM_VER is in third_party/uvm"
fi

# 3. What is available ----------------------------------------------------------------
echo
echo "== Tools on PATH =="
for t in verilator z3 xvlog xelab xsim git make; do
  if have "$t"; then
    printf '  %-10s %s\n' "$t" "$(command -v "$t")"
  else
    printf '  %-10s not found\n' "$t"
  fi
done
if have verilator; then
  echo "  Verilator version: $(verilator --version 2>/dev/null | head -n 1)"
fi

echo
echo "Next:"
if have verilator; then
  echo "  make regress SIM=verilator   (or: bash scripts/regress.sh -s verilator)"
else
  echo "  make verilator-build         (then: make regress SIM=verilator)"
fi
if have xvlog; then
  echo "  make regress SIM=xsim        (or: bash scripts/regress.sh -s xsim)"
fi
echo "  make playground              (two files to paste into EDA Playground)"
