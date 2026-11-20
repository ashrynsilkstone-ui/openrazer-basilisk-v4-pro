# OpenRazer Basilisk V4 Pro test build

These packages contain the experimental driver, D-Bus daemon and Python client
from the Basilisk V4 Pro branch. The [release](https://github.com/ashrynsilkstone-ui/openrazer-basilisk-v4-pro/releases/tag/testbuild-20261120)
includes a source archive, SHA-256 checksums and the package sets below.
[Basilisk V4 Pro Tray for KDE](https://github.com/ashrynsilkstone-ui/basilisk-v4-tray)
is available separately.

| Distribution | Package format and downloads | Build recipe |
| --- | --- | --- |
| CachyOS and Arch Linux | Pacman package set, built on CachyOS | [PKGBUILD](arch/PKGBUILD) |
| Debian | DEB package set, built on Debian 13 (Trixie) | [Debian packaging](../../debian) |
| Ubuntu | DEB package set, built on Ubuntu 24.04 LTS (Noble) | [Debian packaging](../../debian) |
| Fedora | RPM package set and SRPM, built on Fedora 44 | [RPM spec](rpm/openrazer.spec) |
| Mageia | RPM package set and SRPM, built on Mageia 10 | [RPM spec](rpm/openrazer.spec) |
| openSUSE | RPM package set and SRPM, built on Tumbleweed with Python 3.13 | [RPM spec](rpm/openrazer.spec) |
| Alpine Linux | APK package set, built on Alpine edge (x86_64) | [APKBUILD](alpine/APKBUILD) |
| Gentoo | Portage ebuild for the selected kernel | [Local overlay](gentoo/) |
| NixOS | Nix derivations for the configured kernel and Python | [NixOS module](nixos/module.nix) |
| Slackware | SlackBuild for a kernel-specific TXZ package | [SlackBuild](slackware/openrazer.SlackBuild) |
| Solus | ypkg recipe for the LTS and current kernels | [package.yml](solus/package.yml) |
| Void Linux | XBPS package set, built on Void glibc (x86_64) | [XBPS template](void/template) |

The package sets have distribution-specific dependencies and paths. Choose the
set for your distribution and keep all components at the same version.
Before installing a DKMS or AKMS package, install the headers that match the
kernel you use. Secure Boot systems may require module signing; see the
[upstream troubleshooting guide](https://github.com/openrazer/openrazer/wiki/Troubleshooting).
Use the release's `SHA256SUMS` to check any downloaded assets. The RPM
prerelease assets are unsigned and may require confirmation in the package
manager.

## Install a package set

Extract the archive for your distribution into a new directory and run its
package-manager command there.

| Distribution | Command |
| --- | --- |
| CachyOS / Arch Linux | `sudo pacman -U ./*.pkg.tar.zst` |
| Debian 13 / Ubuntu 24.04 | `sudo apt install ./*.deb` |
| Fedora 44 | `sudo dnf install ./*.noarch.rpm` |
| Mageia 10 | `sudo urpmi ./*.noarch.rpm` |
| openSUSE Tumbleweed | `sudo zypper install ./*.noarch.rpm` |
| Alpine edge | `doas apk --keys-dir "$PWD/keys" add ./openrazer-[0-9]*.apk ./openrazer-src-*.apk ./openrazer-udev-*.apk ./py3-openrazer-*.apk` |
| Void glibc (x86_64) | `sudo xbps-install --repository="$PWD" openrazer-meta` |

The Alpine archive contains a `keys/` directory with the test build's public
signing key. Copy the stock repository keys into it with
`cp /etc/apk/keys/*.pub ./keys/` before using it as your `--keys-dir`.
The main APK installs an XDG autostart entry. The optional
`openrazer-systemd` subpackage supplies a systemd user service.

On CachyOS and Arch, join the `openrazer` group. On Debian, Ubuntu, Fedora,
Mageia, openSUSE, Alpine, Gentoo, Slackware, Solus and Void, use `plugdev`.
An Alpine system without that group can create it with `doas addgroup -S plugdev`.
On NixOS, the module adds the provided user to the `openrazer` group.
Log out and back in after the change, then reconnect the mouse or reboot to
load the new kernel module and refresh udev permissions.

## Build from source

Use the release's `openrazer-3.12.4.20261120.tar.xz` alongside the recipes.
From a Git checkout, `sh packaging/testbuild/make-source.sh` recreates the
archive in `dist/` from the tracked driver revision in [revision](revision).
The build commands below are run on the target distribution unless specified.

### CachyOS and Arch Linux

Install the build tools from `base-devel` and `python-setuptools`. Place the
[PKGBUILD](arch/PKGBUILD) and source archive in the same directory and run
`makepkg -s` as a regular user.

### Debian and Ubuntu

Install `build-essential`, `debhelper`, `dh-python`, `dh-dkms`,
`python3-setuptools` and `xz-utils`. From the repository root, run:

```sh
sh packaging/testbuild/build-deb.sh ./dist/openrazer-3.12.4.20261120.tar.xz
```

### Fedora, Mageia and openSUSE

Install `rpm-build`, `make`, `python3-devel` and `python3-setuptools` in the
target distribution. The spec selects dependency names and DKMS handling
using the distribution's RPM macros. From the repository root, run:

```sh
sh packaging/testbuild/build-rpm.sh ./dist/openrazer-3.12.4.20261120.tar.xz
```

### Alpine Linux

Install `alpine-sdk` and configure a signing key with `abuild-keygen -a -i`.
Put [APKBUILD](alpine/APKBUILD) and the source archive in the same directory.
Run `abuild -r` as a member of the `abuild` group. Install the driver sources
subpackage and your kernel headers for AKMS to compile the modules.

### Gentoo

Register the [local overlay](gentoo/) in `/etc/portage/repos.conf` with its
absolute location and `auto-sync = no`. Download the source archive into
`$(portageq distdir)` and accept your architecture keyword for
`=sys-apps/openrazer-3.12.4.20261120::basilisk-testbuild` in
`/etc/portage/package.accept_keywords`. Select the configured kernel sources
and build with:

```sh
sudo emerge -av =sys-apps/openrazer-3.12.4.20261120::basilisk-testbuild
```

### NixOS

Put the source archive where your NixOS configuration can reference it as a
path. Add the [module](nixos/module.nix) to your configuration's `imports`:

```nix
(import ./openrazer-testbuild/module.nix {
  archive = ./openrazer-testbuild/openrazer-3.12.4.20261120.tar.xz;
  user = "your-login";
})
```

Add both files to Git if the configuration is a tracked flake. Run
`sudo nixos-rebuild test` to build and activate for the configured kernel.

### Slackware

Place [openrazer.SlackBuild](slackware/openrazer.SlackBuild) and the source
archive together. Install the configured kernel source, build tools and
the OpenRazer daemon's [SlackBuild dependencies](https://slackbuilds.org/repository/15.0/system/openrazer-daemon/).
Run `sh openrazer.SlackBuild` as root in a build environment. Set `KERNEL`
and `KERNELDIR` if building for a different kernel. The resulting `.txz`
in `/tmp` includes kernel modules, daemon and Python client. If migrating
from SlackBuilds.org, uninstall its split OpenRazer packages before
installing this combined package with `installpkg`.

### Solus

Use the [Solus packaging setup](https://help.getsol.us/docs/packaging/).
Copy [package.yml](solus/package.yml) to a packaging directory. Set its source
URL to `file:///absolute/path/openrazer-3.12.4.20261120.tar.xz` for a local
download of the private release asset, and keep the SHA-256 value as-is.
Run `sudo solbuild build package.yml`. Install the `openrazer-common`
package and the module package for your installed kernel (LTS or current).

### Void Linux

Use a [void-packages checkout](https://github.com/void-linux/void-packages).
Replace `srcpkgs/openrazer-meta/template` with the [test template](void/template)
and copy the release source archive into
`hostdir/sources/openrazer-meta-3.12.4.20261120/`. From that checkout run
`./xbps-src binary-bootstrap` and `./xbps-src pkg openrazer-meta`. Install
against the generated local repository with
`sudo xbps-install --repository="$PWD/hostdir/binpkgs" openrazer-meta`.

The Gentoo, Solus and Void recipes are derived from the corresponding
distribution's OpenRazer packaging. The remaining recipes stage files using
the OpenRazer build system.
