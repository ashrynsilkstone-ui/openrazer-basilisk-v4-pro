#!/bin/sh
# SPDX-License-Identifier: GPL-2.0-or-later
set -eu

test "$#" -ge 1 && test "$#" -le 2 || {
    printf 'Usage: %s path/to/openrazer-source.tar.xz [output-directory]\n' "$0" >&2
    exit 2
}
archive=$(realpath "$1")
name=$(basename "$archive" .tar.xz)
version=${name#openrazer-}
mkdir -p "${2:-dist}"
output=$(CDPATH= cd -- "${2:-dist}" && pwd)
build=$(mktemp -d)
trap 'rm -rf -- "$build"' EXIT
trap 'exit 1' HUP INT TERM

tar -xf "$archive" -C "$build"
cp "$archive" "$build/openrazer_${version}.orig.tar.xz"
cd "$build/$name"
dpkg-buildpackage -us -uc --build=any,all
cp "$build"/*.deb "$output/"
