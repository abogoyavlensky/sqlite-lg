# sqlite-lg

Embedded SQLite for [let-go](https://github.com/nooga/let-go), running in-process
via WebAssembly (wazero) — no cgo, no external database, no separate process.

`sqlite-lg` loads a WASI build of the SQLite amalgamation through let-go's
built-in `wasm` host and exposes a small, next-jdbc-shaped API.

## Requirements

- A **wasm-capable `lg`** (≥ 1.11.0) — an `lg` whose runtime includes the `wasm`
  namespace. Until that ships in a release, build it from the let-go `wazero`
  branch (`CGO_ENABLED=0 go build -o lg .`).
- `sqlite3.wasm` on the resource path (shipped in `resources/`).

## Usage

```clojure
(require '[sqlite])

(def db (sqlite/open ":memory:"))          ; or a file path, e.g. "app.db"

(sqlite/execute! db "create table users (id integer primary key, name text, score real)")
(sqlite/execute! db "insert into users (name, score) values (?, ?)" "Alice" 9.5)

(sqlite/query db "select * from users where score > ?" 8)
;; => [{:id 1 :name "Alice" :score 9.5}]

(sqlite/close db)
```

Run with a wasm-capable `lg` (until lgx ships wasm-dep support):

```sh
lg -source-paths src -resource-paths resources your-app.lg
```

## API

- `(sqlite/open path)` — open/create a database. `":memory:"` for in-memory; a
  relative path (e.g. `"app.db"`) for a file in the current directory. Returns a
  db handle.
- `(sqlite/execute! db sql & params)` — run DDL/DML; `?` placeholders bind the
  trailing args. Returns `{:rows-affected n :last-insert-id m}`.
- `(sqlite/query db sql & params)` — run a query; returns a vector of row maps
  with keywordized columns and typed values (INTEGER→int, REAL→float,
  TEXT→string, NULL→nil).
- `(sqlite/close db)` — close a handle.

## Notes & limitations (v1)

- **File databases** are relative to the process's current directory (mounted for
  WASI); `:memory:` needs no filesystem.
- **Single-writer.** WASI has no file locking, so file databases are safe for a
  single process/connection only — not concurrent writers.
- BLOBs come back as raw bytes (best-effort). Transactions, prepared-statement
  reuse, and pragmas are not yet wrapped.

## As a dependency (lgx)

```clojure
;; lgx.edn
{:deps {sqlite {:git/url "https://github.com/abogoyavlensky/sqlite-lg"
                :git/sha "..."}}}
```

Once lgx ships wasm-dep support, `sqlite-lg` declares `:lgx/lib {:resources true}`
(to expose `sqlite3.wasm` to consumers) and `:lgx/min-lg-version "1.11.0"`; lgx then
puts the resource on the path and verifies your `lg` is new enough.

## Rebuilding `sqlite3.wasm`

The built module is committed in `resources/`. Rebuilding needs wasi-sdk (clang +
WASI sysroot), declared in `.mise.toml` and installed via mise's `github:`
backend (same as `lg`/`lgx`):

```sh
mise install      # installs wasi-sdk (github:WebAssembly/wasi-sdk) for your OS/arch
lgx build-wasm    # compile resources/sqlite3.wasm from the SQLite amalgamation
```

`build-wasm` resolves wasi-sdk via `mise where wasi-sdk` (or `$WASI_SDK_PATH` if
set), then runs `scripts/build-wasm.sh`.

> Note: the wasi-sdk **asdf** plugin (`asdf:…`) is broken (pre-v25, non-arch URL,
> no arm64); mise's **`github:`** backend works and is what `.mise.toml` uses.
