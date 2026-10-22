{
  config,
  lib,
  pkgs,
  ...
}:
let
  hostName = "reminix"; # Define your hostname.
in
{
  imports = [
    ../../linux/gui.nix
  ];

  modules.desktop.niri.enable = true;
  modules.desktop.gaming.enable = false;

  # Plain nushell in new terminals; tuios stays installed for manual use.
  modules.tuios.autoStart = false;

  xdg.configFile."niri/niri-hardware.kdl".source = ../../../hosts/reminix/niri-hardware.kdl;

  # Ghostty 1.3.1 needs OpenGL 4.3; UTM's Core OpenGL backend exposes at most 4.1.
  # Limit the software renderer to Ghostty, leaving niri and Kitty accelerated.
  programs.ghostty.package = lib.mkForce (
    pkgs.symlinkJoin {
      name = "ghostty-reminix";
      paths = [ pkgs.ghostty ];
      nativeBuildInputs = [ pkgs.makeWrapper ];
      meta = pkgs.ghostty.meta;
      postBuild = ''
        wrapProgram $out/bin/ghostty --set LIBGL_ALWAYS_SOFTWARE 1

        # The upstream D-Bus and systemd units hardcode the unwrapped binary;
        # point them at the wrapper so every launch path gets the same renderer.
        for unit in \
          share/systemd/user/app-com.mitchellh.ghostty.service \
          share/dbus-1/services/com.mitchellh.ghostty.service; do
          rm "$out/$unit"
          substitute "${pkgs.ghostty}/$unit" "$out/$unit" \
            --replace-fail "${pkgs.ghostty}/bin/ghostty" "$out/bin/ghostty"
        done
      '';
    }
  );

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
