#!/bin/sh
# SPDX-License-Identifier: GPL-2.0-or-later
set -eu

packaging_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
repo=$(git -C "$packaging_dir" rev-parse --show-toplevel)
version=$(cat "$packaging_dir/version")
revision=$(git -C "$repo" rev-parse "${2:-$(cat "$packaging_dir/revision")}^{commit}")
epoch=$(git -C "$repo" show -s --format=%ct "$revision")
mkdir -p "${1:-dist}"
output=$(CDPATH= cd -- "${1:-dist}" && pwd)
build=$(mktemp -d)
trap 'rm -rf -- "$build"' EXIT
trap 'exit 1' HUP INT TERM

name=openrazer-$version
git -C "$repo" archive --format=tar --prefix="$name/" "$revision" > "$build/source.tar"
tar -xf "$build/source.tar" -C "$build"
cd "$build/$name"
# Keep the DKMS source directory, module config and Python metadata in sync.
sed -i -e "s/DKMS_VER?=.*/DKMS_VER?=$version/" Makefile
sed -i -e "s/^PACKAGE_VERSION=.*/PACKAGE_VERSION=\"$version\"/" install_files/dkms/dkms.conf
sed -i -e "s/^#define DRIVER_VERSION .*/#define DRIVER_VERSION \"$version\"/" driver/razercommon.h
sed -i -e "s/__version__ = .*/__version__ = '$version'/" \
    daemon/openrazer_daemon/daemon.py pylib/openrazer/client/device_manager.py
sed -i -e "s/version=\"[^\"]*\"/version=\"$version\"/" daemon/setup.py pylib/setup.py
{
    printf 'openrazer (%s-1) unstable; urgency=medium\n\n' "$version"
    printf '  * Basilisk V4 Pro test build from %s.\n\n' "$revision"
    printf ' -- Basilisk V4 Pro Test Builds <ashrynsilkstone-ui@users.noreply.github.com>  '
    LC_ALL=C date -u -R -d "@$epoch"
    printf '\n'
    cat debian/changelog
} > debian/changelog.testbuild
mv debian/changelog.testbuild debian/changelog
printf '%s\n' "$revision" > TESTBUILD_SOURCE
cd "$build"
export XZ_DEFAULTS=--threads=1
tar --sort=name --mtime="@$epoch" --owner=0 --group=0 --numeric-owner -cJf "$name.tar.xz" "$name"
mv "$name.tar.xz" "$output/$name.tar.xz"
printf '%s\n' "$output/$name.tar.xz"
