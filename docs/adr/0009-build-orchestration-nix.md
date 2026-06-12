# ADR-0009: Build orchestration with Nix, adopted in stages

Status: Accepted (2026-06-12)

## Context

The monorepo (ADR-0008) spans Haskell, Rust, TypeScript, Swift and
Python. Each has a good native build tool; none of them can pin the
*others'* toolchains, so "works on my machine" failures multiply with
every subproject. Candidates considered:

- **Bazel** — hermetic build *actions* at huge scale. Rejected:
  `rules_haskell` is niche, abandons stack, fights cross-compilation,
  and has no support for GHC's WebAssembly backend, which is on our
  roadmap. At ~8 subprojects we would pay Google-scale overhead without
  Google-scale payoff.
- **Nix** — reproducible *packages and environments*. The de-facto
  standard in the Haskell community; `ghc-wasm-meta` (the GHC wasm
  toolchain) ships Nix-first; and the Nix language is itself lazy, pure
  and functional — practicing the very concepts this project exists to
  teach.

## Decision

Nix, in two stages:

1. **Dev shells first.** A root `flake.nix` provides per-subproject
   shells (`nix develop .#core`, `.#ocr`, …) pinning GHC/stack, cargo,
   node/pnpm, python+opencv+tesseract. The native tools still do the
   inner builds; Nix only guarantees everyone (including CI) runs
   identical toolchains.
2. **Hermetic artifact builds later**, per artifact, when a subproject
   benefits (e.g. building `libhudoku.dylib` or the wasm module as a
   `nix build` derivation).

## Consequences

- stack/cargo/pnpm workflows stay exactly as they are; Nix wraps them.
- CI installs Nix and enters the same shells the developer uses.
- The wasm toolchain becomes one flake input instead of a hand-rolled
  cross-compiler setup.
- Cost: learning the Nix language and its (famously cryptic) error
  messages — accepted deliberately as part of the project's learning
  goals.
