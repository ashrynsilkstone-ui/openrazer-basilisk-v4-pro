# SPDX-License-Identifier: GPL-2.0-or-later
{ archive, user }:
{ config, pkgs, ... }:
let
  version = "3.12.4.20261120";
  sourceName = "openrazer-${version}";
  src = builtins.path {
    path = archive;
    name = "${sourceName}.tar.xz";
  };
  pythonOverlay = _: prev: {
    pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
      (_: pyPrev: {
        openrazer-daemon = pyPrev.openrazer-daemon.overridePythonAttrs (_: {
          inherit src version;
          sourceRoot = "${sourceName}/daemon";
        });
        openrazer = pyPrev.openrazer.overridePythonAttrs (_: {
          inherit src version;
          sourceRoot = "${sourceName}/pylib";
        });
      })
    ];
  };
in
{
  nixpkgs.overlays = [ pythonOverlay ];
  hardware.openrazer = {
    enable = true;
    users = [ user ];
    packages.kernel = config.boot.kernelPackages.openrazer.overrideAttrs (_: {
      inherit src;
      version = "${version}-${config.boot.kernelPackages.kernel.version}";
    });
  };
  environment.systemPackages = [ (pkgs.python3.withPackages (ps: [ ps.openrazer ])) ];
}
