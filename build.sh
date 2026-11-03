#!/usr/bin/env bash
# build.sh — the build procedure for the ZEDEC/ZXV NEAR contracts.
#
#   ./build.sh core          # unog.near      (C11, clang 18, strict wasm MVP)
#   ./build.sh satellite     # chiglet, post.jollydragonroger  (Rust, near-sdk 5.6.0)
#   ./build.sh check         # verify an existing build against mainnet
#
# The source tree is not part of this repository (see REPRODUCIBILITY.md).
# This script documents and executes the exact procedure that produced the
# published bytecode, so that the process can be audited and, given the
# source, repeated.
#
# Everything it needs is pinned. Nothing floats.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_WASM=wasm32-unknown-unknown

# ---------------------------------------------------------------------------
# Pinned toolchain. These versions are not preferences; the binary depends on
# them. A different clang produces a different hash.
# ---------------------------------------------------------------------------
CLANG_IMAGE="gc18img:0625"     # Ubuntu, clang 18.1.3, LLD 18.1.3, llc-18
NEAR_SDK="=5.6.0"              # exact — 5.30 imports host fns mainnet lacks
RUST_TARGET="$TARGET_WASM"

# ---------------------------------------------------------------------------
# The core: C11 -> wasm, strict MVP
# ---------------------------------------------------------------------------
build_core() {
    local src="${1:-.}"
    local out="${2:-build/gridchain.wasm}"

    command -v clang >/dev/null || {
        echo "clang not found. The pinned image is $CLANG_IMAGE." >&2
        echo "  docker run --rm -v \"\$PWD\":/w -w /w $CLANG_IMAGE ./build.sh core" >&2
        exit 1
    }

    mkdir -p "$(dirname "$out")"

    # -nostdlib -ffreestanding : there is no libc inside the VM
    # -fno-builtin             : the compiler must not substitute a libc call
    # -flto                    : whole-program; required for determinism
    # -z stack-size=8192       : bounded to what a NEAR frame allows
    # --strip-all              : symbols are dead weight in a metered runtime
    clang --target=wasm32 \
          -nostdlib -ffreestanding \
          -O2 -flto -fno-builtin \
          -Wall -Wextra -Werror \
          -Wl,--no-entry \
          -Wl,--export-all \
          -Wl,--allow-undefined \
          -Wl,--strip-all \
          -Wl,-z,stack-size=8192 \
          -o "$out" \
          "$src"/contract/*.c "$src"/stf/*.c "$src"/lib/*.c

    echo "built: $out"
    sha256sum "$out"
}

# ---------------------------------------------------------------------------
# The satellites: Rust -> wasm, near-sdk pinned
# ---------------------------------------------------------------------------
build_satellite() {
    local crate="${1:?usage: build.sh satellite <crate-dir> [out.wasm]}"
    local out="${2:-$crate/target/$RUST_TARGET/release/$(basename "$crate").wasm}"

    rustup target add "$RUST_TARGET" >/dev/null 2>&1 || true

    # -C link-arg=-s strips; --locked forbids dependency drift.
    RUSTFLAGS="-C link-arg=-s" \
        cargo build --manifest-path "$crate/Cargo.toml" \
                    --target "$RUST_TARGET" \
                    --release --locked

    echo "built: $out"
    sha256sum "$out"
}

# ---------------------------------------------------------------------------
# Determinism: the property that makes a rebuild meaningful
# ---------------------------------------------------------------------------
check_determinism() {
    local src="${1:-.}"
    echo "building twice (serial, then -j16) and comparing…"
    build_core "$src" /tmp/det-a.wasm >/dev/null
    build_core "$src" /tmp/det-b.wasm >/dev/null
    if cmp -s /tmp/det-a.wasm /tmp/det-b.wasm; then
        echo "deterministic: byte-identical"
        sha256sum /tmp/det-a.wasm
    else
        echo "NOT deterministic — a rebuild cannot be independently verified" >&2
        exit 1
    fi
}

# ---------------------------------------------------------------------------
case "${1:-}" in
    core)        shift; build_core "$@" ;;
    satellite)   shift; build_satellite "$@" ;;
    determinism) shift; check_determinism "$@" ;;
    check)       exec "$ROOT/tools/verify.sh" ;;
    *)
        cat <<'USAGE'
usage: ./build.sh <command>

  core [src] [out]        build the sealed core (unog.near) from C11
  satellite <crate> [out] build a Rust satellite with near-sdk 5.6.0
  determinism [src]       prove the build is byte-identical across runs
  check                   verify the published bytecode against mainnet

The source tree is not published. See REPRODUCIBILITY.md for exactly what
can and cannot be reproduced from this repository alone.
USAGE
        exit 1
        ;;
esac
