# Build resources/sqlite3.wasm from the SQLite amalgamation using wasi-sdk.
#
# Requires wasi-sdk (see ../README.md for install). Override WASI_SDK_PATH if
# it lives elsewhere:  make WASI_SDK_PATH=/opt/wasi-sdk
#
# Produces a WASI "reactor" module (exports _initialize, no _start) exporting
# the SQLite C-API subset the `sqlite` namespace calls, plus malloc/free.

WASI_SDK_PATH ?= $(HOME)/wasi-sdk
SQLITE_VERSION ?= 3530200
SQLITE_YEAR ?= 2026
AMALG_URL = https://www.sqlite.org/$(SQLITE_YEAR)/sqlite-amalgamation-$(SQLITE_VERSION).zip

CLANG = $(WASI_SDK_PATH)/bin/clang
OUT = ../resources/sqlite3.wasm

CFLAGS = -mexec-model=reactor -O2 \
	-DSQLITE_THREADSAFE=0 -DSQLITE_OMIT_LOAD_EXTENSION -DSQLITE_OMIT_WAL -DSQLITE_DQS=0 \
	--sysroot=$(WASI_SDK_PATH)/share/wasi-sysroot

EXPORTS = sqlite3_open_v2 sqlite3_close_v2 sqlite3_prepare_v2 \
	sqlite3_bind_text sqlite3_bind_int64 sqlite3_bind_double sqlite3_bind_null \
	sqlite3_step sqlite3_reset sqlite3_finalize \
	sqlite3_column_count sqlite3_column_name sqlite3_column_type \
	sqlite3_column_int64 sqlite3_column_double sqlite3_column_text sqlite3_column_bytes \
	sqlite3_changes sqlite3_last_insert_rowid sqlite3_errmsg \
	sqlite3_exec sqlite3_free malloc free
LDFLAGS = $(foreach e,$(EXPORTS),-Wl,--export=$(e))

.PHONY: all clean
all: $(OUT)

# Fetch + unpack the amalgamation (skipped once sqlite3.c exists).
sqlite3.c:
	curl -fsSL -o amalg.zip "$(AMALG_URL)"
	unzip -q -o amalg.zip
	mv sqlite-amalgamation-*/sqlite3.c sqlite-amalgamation-*/sqlite3.h .
	rm -rf sqlite-amalgamation-* amalg.zip

$(OUT): sqlite3.c
	$(CLANG) $(CFLAGS) sqlite3.c $(LDFLAGS) -o $(OUT)

clean:
	rm -f sqlite3.c sqlite3.h $(OUT)
