{ config, lib, ... }:
let
  hostName = "reminix"; # Define your hostname.
in
{
  imports = [
    ../../linux/gui.nix
  ];

  modules.desktop.niri.enable = true;
  modules.desktop.gaming.enable = false;

  # Not needed on a dev VM: bambu-studio has no aarch64 binary in the cache and
  # takes over an hour to compile, blender alone is several GB.
  modules.desktop.creative.enable = false;
  # dl.google.com is unreachable from this network, so the unfree .deb that the
  # package wraps can never be fetched; chromium and brave remain.
  programs.google-chrome.enable = lib.mkForce false;

  # A VM window on the Mac: no real keyboard backlight or panel to save, so keep
  # the idle chain lenient and mostly as a lock-after-absence safeguard.
  modules.desktop.hypridle = {
    keyboardBacklightTimeout = 600;
    screenOffTimeout = 1800;
    lockTimeout = 3600;
  };

  # The SSH identity used for GitHub is the host key half that lives on the Mac;
  # keep the same per-host filename convention as the physical hosts.
  programs.ssh.settings."github.com".IdentityFile = "${config.home.homeDirectory}/.ssh/${hostName}";
}
