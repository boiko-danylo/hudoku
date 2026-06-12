# ADR-0008: Monorepo layout and subproject roadmap

Status: Accepted (2026-06-12)

## Context

Hudoku is outgrowing a single Haskell package. The goal is a family of
products around one solver core: a CLI, an HTTP API, a web SPA, an iOS
app, a desktop GUI — plus the existing OCR pipeline. Splitting into many
repositories would multiply CI setups, version coordination and drift;
the corpus alone is consumed by both the Haskell tests and the Python
OCR tuning, so it must not live "inside" either.

## Decision

One monorepo. Subprojects are top-level directories without a `hudoku-`
prefix (redundant inside the repo); package/artifact names keep it.

Existing today:

| Directory | Contents |
|-----------|----------|
| `core/`   | `hudoku-core` — the Haskell solver library, example exe, tests |
| `corpus/` | Ground-truth puzzle data (root-level on purpose: shared by core tests and OCR), plus `verify.hs` |
| `ocr/`    | Python/OpenCV ingestion pipeline and live viewer |

Planned, in build order:

| Directory | Contents | Notes |
|-----------|----------|-------|
| `protocol/` | `hudoku-protocol` — JSON encode/decode of the solve request/response (aeson) | shared by all bindings; defined in its own ADR when built |
| `libhudoku/` | C-ABI shared library over the core (`foreign export ccall`) | serialized boundary: strings in, JSON out |
| `wasm/`   | WebAssembly build of the core (GHC wasm backend, `ghc-wasm-meta`) | same protocol; enables in-browser solving |
| `cli/`    | Haskell CLI **on the core directly** (not via libhudoku) | full access to rich types; learning ground for optparse-applicative |
| `api/`    | Rust HTTP backend linking libhudoku | the permanent integration test of the C ABI; later also a `/scan` OCR endpoint |
| `spa/`    | Next.js app consuming the api (later: the wasm core) | |
| `gui/`    | Cross-platform desktop app | framework undecided (Tauri considered and rejected) |
| `ios/`    | iOS app | v1 strategy deliberately deferred: API-first vs embedded core (wasm or cross-GHC) |

The architectural through-line is **one protocol, three artifacts**: the
same puzzle-in / `{outcome, grid, steps}`-out JSON shape is exposed via
the C ABI (libhudoku), WebAssembly (wasm) and HTTP (api). Clients code
against the protocol and never care which transport carries it.

Haskell packages share the root `stack.yaml` (multi-package project);
every other subproject keeps its native toolchain (cargo, pnpm,
xcodebuild, pip). Orchestration is ADR-0009.

## Consequences

- Tests run with cwd = package dir, so `core/` test code reaches the
  corpus via `../corpus/`.
- The package was renamed `Hudoku` → `hudoku-core`; the generated
  `.cabal` file is no longer committed (hpack regenerates it).
- New subprojects appear one at a time, each landing with working code
  and its own ADR where a real decision is made — no empty scaffolds.
- OCR stays Python: it is pipeline tooling, not an embeddable library.
  If apps ever need on-device scanning, that is a new subproject
  (Vision/CoreML or OpenCV-C++), not a port of `ocr/`.
