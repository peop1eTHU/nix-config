{ lib, config, pkgs, ... }:
let
  cfg = config.modules.nix.mirrors;
  # The mainland mirrors of the NixOS binary cache. They proxy cache.nixos.org, so
  # they keep its signing key. Ordered by coverage of a recent nixos-unstable pin
  # (measured 2026-10): SJTUG and USTC had every path, NJU lagged, TUNA lagged
  # the most and is left out. Check a path with:
  #   curl -s -o /dev/null -w '%{http_code}' https://<mirror>/<hash>.narinfo
  cnMirrors = [
    "https://mirrors.sjtug.sjtu.edu.cn/nix-channels/store"
    "https://mirrors.ustc.edu.cn/nix-channels/store"
    "https://mirror.nju.edu.cn/nix-channels/store"
  ];
in
{
  options.modules.nix.mirrors.enable = lib.mkEnableOption "Mainland China mirrors for the Nix binary cache";

  # Nix 2.35 is newer than nixpkgs' nixVersions.stable (still 2.34), so opt into
  # the latest released version until stable catches up.
  # https://github.com/NixOS/nixpkgs/blob/nixos-unstable/pkgs/tools/package-management/nix/default.nix
  config = {
  nix.package = pkgs.nixVersions.latest;

  # https://lix.systems/add-to-config/
  # nix.package = pkgs.lix;

  # to install chrome, you need to enable unfree packages
  nixpkgs.config.allowUnfree = lib.mkDefault true;

  # do garbage collection weekly to keep disk usage low
  nix.gc = {
    automatic = lib.mkDefault true;
    dates = lib.mkDefault "weekly";
    options = lib.mkDefault "--delete-older-than 7d";
  };

  # Manual optimise storage: nix-store --optimise
  # https://nixos.org/manual/nix/stable/command-ref/conf-file.html#conf-auto-optimise-store
  nix.settings = {
    auto-optimise-store = true;

    # Required to run nixpkgs' systemd-nspawn based NixOS tests locally (used
    # by the nixpkgs-review workflow). These are daemon-wide settings, so every
    # local build pays the small uid/cgroup allocation overhead; drop them if
    # you stop running those tests.
    # Reference: https://github.com/NixOS/nixpkgs/pull/478109
    auto-allocate-uids = true;
    extra-system-features = [ "uid-range" ];
    experimental-features = [
      "auto-allocate-uids"
      "cgroups"
    ];
    # Use extra-sandbox-paths instead of sandbox-paths here. The plain
    # sandbox-paths setting replaces Nix's compiled sandbox defaults, including
    # the sandbox shell that provides /bin/sh for builders with legacy shebangs.
    # extra-sandbox-paths keeps those defaults and only adds the paths we need.
    # After deploying, verify the effective daemon config with:
    #   nix config show | grep sandbox-paths
    extra-sandbox-paths = [
      "/dev/net"
    ];
  }
  // lib.optionalAttrs cfg.enable {
    # Mainland mirrors of the NixOS binary cache. They proxy cache.nixos.org and
    # serve its signature, so `trusted-public-keys` stays untouched. `mkBefore`
    # prepends without dropping the defaults, so a mirror miss still falls back
    # to the official cache.
    substituters = lib.mkBefore cnMirrors;
  };

  nix.channel.enable = false; # remove nix-channel related tools & configs, we use flakes instead.
  };
}
