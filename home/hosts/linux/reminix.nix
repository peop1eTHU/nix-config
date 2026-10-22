{ config, ... }:
let
  hostName = "reminix"; # Define your hostname.
in
{
  imports = [
    ../../linux/gui.nix
  ];

  modules.desktop.niri.enable = true;
  modules.desktop.gaming.enable = false;

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
