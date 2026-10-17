# ProsperoStore Apple Silicon Mac / PS5 Build Report

## Scope

This report documents the workstation and build findings from the ProsperoStore work associated with:

- [ProsperoStore #30](https://github.com/blackbearreloaded/ProsperoStore/pull/30) — catalog revalidation and Mac build boundary
- [ps5-native-app-boilerplate #13](https://github.com/blackbearreloaded/ps5-native-app-boilerplate/pull/13) — Mac host checks
- [ProsperoStore #31](https://github.com/blackbearreloaded/ProsperoStore/pull/31) — Mac host checks applied to ProsperoStore

## Maintainer finding

Native macOS host checks are practical on Apple Silicon. The final PS5 target link still requires the Linux PS5 LLVM runtime expected by the public Payload SDK. A reproducible Ubuntu AMD64 Docker build on Apple Silicon supplies that runtime without requiring a separate Linux machine or virtual machine.

## Workstation validated

- Apple Silicon macOS host
- Homebrew
- Git, CMake, Ninja, Make
- Python 3 and Node.js
- Apple Clang and Homebrew LLVM
- `clang-format` and `clang-tidy`
- ccache
- Docker Desktop with Ubuntu AMD64 emulation
- PS5 Payload SDK v0.42
- PacBrew dependency support
- pinned OpenGL SDK support
- FTP deployment workflow and PS5 log collection workflow

## Build result

The Docker build completed the following stages:

1. PS5 SDK and runtime preparation
2. Clean-room `libc.prx` generation and verification
3. Store worker ELF build and loader validation
4. Self-update helper ELF build and loader validation
5. Native application compilation and PS5 target link
6. PPSA folder assembly and ZIP creation

Generated title:

- Title ID: `PPSA99000`
- Name: `ProsperoStore`
- Version: `01.000.070`

Output folder:

`dist/PPSA99000/`

The folder contains `eboot.bin`, `sce_sys`, `sce_module/libc.prx`, `lapy.elf`, `store-worker.elf`, `self-updater.elf`, assets, and licenses.

## Checksums

```text
eboot.bin
ca44b3a20192fade56441f8c7d09255139e0ab02b68f0c5936b473b19207eca2

PPSA99000.zip
d10da82a482626ffc6b77dd48e417ea1ee18eeb9a5b2080c1bdc62d688301ff3

runtime/libc.prx
e6ff45d16adf687855cc3b33b0c8a4132b6504360b221e0a34c7e99fb3ba0036
```

## Compatibility fixes made during validation

- Host tools select the available versioned LLVM compiler in Linux containers.
- Host packaging links against host zlib instead of PS5-target zlib.
- Executable-writer tests use host zlib and support explicit host zlib overrides.
- PacBrew compatibility tests select configured host C and C++ compilers.
- Docker/macOS shared-folder handling was normalized for the SDK's intentionally empty archive/object placeholders and small asset index files.

These fixes preserve the PS5 target toolchain and do not change the PS5 application format.

## Validation evidence

- `libc.prx` integrity verified against the expected signed hash.
- `eboot.bin` container integrity verified.
- Store worker ELF framing validated.
- Self-update helper ELF framing validated.
- Host unit tests passed: 3 tests.
- Host integration tests passed: 17 tests in the successful run.
- Update-check and Lapy client/proof checks passed.
- PacBrew curl compatibility test passed after compiler-selection fix.

## PS5 test status

The PPSA folder is ready for deployment to a jailbroken PS5 for manual testing. The remaining work is console-side validation: FTP staging, launch, catalog refresh, update detection, and log collection. No claim is made about those behaviors until they are exercised on hardware.

## Recommendation

Add a Mac workstation document to the boilerplate and ProsperoStore repositories that describes the native host checks plus the Ubuntu AMD64 Docker boundary for final PS5 target builds. Share the PPSA ZIP as a release/test artifact with the checksums above rather than committing generated binaries to the source repository.
