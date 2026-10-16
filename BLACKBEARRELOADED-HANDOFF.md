# ProsperoStore Mac workstation handoff

## Scope

This checkout contains the Mac-side fixes needed to make catalog refreshes
revalidate promptly and to let the host checks run on Apple Silicon macOS.

## Verified changes

- `src/net/curl_request.cpp`: catalog HTTP requests send `Cache-Control:
  no-cache` and `Pragma: no-cache`, while retaining ETag validation.
- `Makefile`: host tests do not pass the Linux/PS5-only `--gc-sections` linker
  option to Apple `ld`.
- `tools/sha256sum`: macOS compatibility wrapper using `shasum`.
- `tools/setup-native-dependencies.sh`: macOS archive-tool flags for zlib.
- `tools/rebuild-libc.sh`: macOS-compatible file-size check.
- `tools/prepare-opengl.sh`: captures the SDK prefix correctly and falls back
  to the available Clang executable.

## Validation

`make test-update-check` passes on the M2 Mac.

The clean-room runtime reproduces the expected hashes:

- Raw: `8ee6e124993e1af26420cb455890fd002f5d6c7e78883c860ce45734e7d002bb`
- Signed: `e6ff45d16adf687855cc3b33b0c8a4132b6504360b221e0a34c7e99fb3ba0036`

The pinned OpenGL SDK archive also verifies successfully.

## Remaining Linux-side step

The full PS5 app link cannot finish on this Mac because the pinned SDK wrappers
expect a Linux LLVM installation and the target runtime archive is absent:

`lib/linux/libclang_rt.builtins-x86_64.a`

The SDK contains wrapper scripts such as `prospero-clang` and `prospero-lld`,
but their configured LLVM bindir resolves to `/llvm-clang`, which is not present
on macOS. Apple Clang cannot substitute this PS5/Linux target runtime safely.

Please finish the final build in the project’s Linux/CI environment with the
pinned PS5 LLVM toolchain, then run the normal PS5 packaging and signing steps.

## Reproduction command

From this checkout:

```text
make USE_CCACHE=0 app
```

Expected Mac-side failure if the target LLVM toolchain is unavailable:

```text
missing link input: .../lib/linux/libclang_rt.builtins-x86_64.a
```

No PS5 package or release was produced from this Mac checkout.
