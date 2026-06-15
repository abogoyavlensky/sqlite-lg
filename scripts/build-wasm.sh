#!/usr/bin/env bash
#
# Build resources/sqlite3.wasm from the SQLite amalgamation using wasi-sdk.
# Invoked by `lgx build-wasm`. Uses wasi-sdk at $WASI_SDK_PATH (default
# ~/wasi-sdk); run `lgx setup-wasi-sdk` first to install it.
#
# Produces a WASI "reactor" module (exports _initialize, no _start) exporting
# the SQLite C-API subset the `sqlite` namespace calls, plus malloc/free.
set -euo pipefail

WASI_SDK_PATH="${WASI_SDK_PATH:-$HOME/wasi-sdk}"
if [ ! -x "$WASI_SDK_PATH/bin/clang" ]; then
  echo "wasi-sdk not found at $WASI_SDK_PATH — run 'lgx setup-wasi-sdk' first" >&2
  exit 1
fi

SQLITE_AMALG="${SQLITE_AMALG:-2026/sqlite-amalgamation-3530200.zip}"

root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root"
mkdir -p wasm resources
cd wasm

if [ ! -f sqlite3.c ]; then
  curl -fsSL -o amalg.zip "https://www.sqlite.org/${SQLITE_AMALG}"
  unzip -q -o amalg.zip
  mv sqlite-amalgamation-*/sqlite3.c sqlite-amalgamation-*/sqlite3.h .
  rm -rf sqlite-amalgamation-* amalg.zip
fi

exports="sqlite3_open_v2 sqlite3_close_v2 sqlite3_prepare_v2 \
  sqlite3_bind_text sqlite3_bind_int64 sqlite3_bind_double sqlite3_bind_null \
  sqlite3_step sqlite3_reset sqlite3_finalize \
  sqlite3_column_count sqlite3_column_name sqlite3_column_type \
  sqlite3_column_int64 sqlite3_column_double sqlite3_column_text sqlite3_column_bytes \
  sqlite3_changes sqlite3_last_insert_rowid sqlite3_errmsg \
  sqlite3_exec sqlite3_free malloc free"
flags=""
for e in $exports; do flags="$flags -Wl,--export=$e"; done

# shellcheck disable=SC2086
"$WASI_SDK_PATH/bin/clang" -mexec-model=reactor -O2 \
  -DSQLITE_THREADSAFE=0 -DSQLITE_OMIT_LOAD_EXTENSION -DSQLITE_OMIT_WAL -DSQLITE_DQS=0 \
  --sysroot="$WASI_SDK_PATH/share/wasi-sysroot" \
  sqlite3.c $flags -o ../resources/sqlite3.wasm

echo "built resources/sqlite3.wasm ($(stat -c%s ../resources/sqlite3.wasm) bytes)"
