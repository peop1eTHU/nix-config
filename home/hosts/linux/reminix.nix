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

  # The SSH identity used for GitHub is the host key half that lives on the Mac;
  # keep the same per-host filename convention as the physical hosts.
  programs.ssh.settings."github.com".IdentityFile = "${config.home.homeDirectory}/.ssh/${hostName}";
}
