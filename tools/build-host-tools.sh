#!/usr/bin/env bash
# ps5-native-app-boilerplate - Shared host tools built with Ninja and ccache.
# Copyright (C) 2026 BlackBearReloaded
# SPDX-License-Identifier: GPL-3.0-or-later

set -euo pipefail
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
source "$root/tools/ninja-build.sh"
native="$root/tooling/native"
build="$root/build/host"
zlib_root="$root/.deps/native/zlib/root"
# The cached zlib is built for the PS5 target and must not be linked into
# host-side packaging tools. Prefer the host platform's zlib, with an
# explicit override for CI images that keep it in a non-standard location.
if [[ -n ${HOST_ZLIB_ARCHIVE:-} ]]; then
    zlib_archive="$HOST_ZLIB_ARCHIVE"
    zlib_include="${HOST_ZLIB_INCLUDE:-$zlib_root/usr/include}"
else
    zlib_libdir="$(pkg-config --variable=libdir zlib 2>/dev/null || true)"
    zlib_archive="${zlib_libdir:+$zlib_libdir/libz.a}"
    zlib_include="$(pkg-config --variable=includedir zlib 2>/dev/null || true)"
    [[ -f "$zlib_archive" ]] || zlib_archive="/usr/lib/x86_64-linux-gnu/libz.a"
    [[ -d "$zlib_include" ]] || zlib_include="/usr/include"
fi
if [[ -n ${CXX:-} ]]; then
    cxx=$(command -v "$CXX")
else
    cxx=$(command -v clang++-18 || command -v clang++)
fi
ninja_begin "$build/build.ninja"
objects=()
for name in native_app_builder self_container elf_object sce_module_writer libc_builder; do
    object="$build/$name.o"
    ninja_inputs=("$native/$name.cpp" "$cxx")
    ninja_edge CXX "$object" "${compiler_cache[@]}" "$cxx" \
        -std=c++20 -O2 -Wall -Wextra -Werror -I "$zlib_include" \
        -MD -MF "$object.d" -c "$native/$name.cpp" -o "$object"
    [[ $name == libc_builder ]] || objects+=("$object")
done
ninja_inputs=("${objects[@]}" "$zlib_archive" "$cxx")
ninja_edge LINK "$build/ps5-native-tool" "$cxx" "${objects[@]}" "$zlib_archive" -o "$build/ps5-native-tool"
ninja_inputs=("$build/libc_builder.o" "$cxx")
ninja_edge LINK "$build/libc-builder" "$cxx" "$build/libc_builder.o" -o "$build/libc-builder"
ninja_run
