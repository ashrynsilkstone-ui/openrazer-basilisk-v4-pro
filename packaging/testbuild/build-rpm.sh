#!/bin/sh
# SPDX-License-Identifier: GPL-2.0-or-later
set -eu

test "$#" -ge 1 && test "$#" -le 2 || {
    printf 'Usage: %s path/to/openrazer-source.tar.xz [output-directory]\n' "$0" >&2
    exit 2
}
archive=$(realpath "$1")
packaging_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
mkdir -p "${2:-dist}"
output=$(CDPATH= cd -- "${2:-dist}" && pwd)
build=$(mktemp -d)
trap 'rm -rf -- "$build"' EXIT
trap 'exit 1' HUP INT TERM

mkdir -p "$build/SOURCES"
cp "$archive" "$build/SOURCES/"
rpmbuild -ba --define "_topdir $build" "$packaging_dir/rpm/openrazer.spec"
find "$build/RPMS" "$build/SRPMS" -type f -name '*.rpm' -exec cp {} "$output/" \;
