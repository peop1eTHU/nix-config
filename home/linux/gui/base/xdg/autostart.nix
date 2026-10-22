{
  config,
  lib,
  pkgs,
  ...
}:
let
  # The nixpak wrappers are an overlay that only the hardened desktop hosts
  # import (`hardening/nixpaks`). A host that leaves it out has no `pkgs.nixpaks`
  # attribute, so the autostart entries below are gated on it rather than
  # pointing Home Manager at a package that does not exist.
  hasNixpaks = pkgs ? nixpaks;
in
{
  # XDG autostart entries. All of them are globally ordered after the
  # xdg-desktop-portal stack via `systemd.user.units."app-@autostart.service"`
  # in modules/nixos/desktop/xdg.nix, so sandboxed apps (nixpak: firefox,
  # telegram, ...) don't race the portal at login and end up with broken
  # FileChooser/OpenURI until manually restarted.
  xdg.autostart.enable = true;
  # This fixes nixpak sandboxed apps (like firefox) accessing mapped folders correctly
  xdg.autostart.entries = [
    "${pkgs.ghostty}/share/applications/com.mitchellh.ghostty.desktop"
    "${pkgs.kitty}/share/applications/kitty.desktop"
  ]
  ++ lib.optionals hasNixpaks [
    # nixpaks
    "${pkgs.nixpaks.firefox}/share/applications/org.mozilla.firefox.desktop"
    "${pkgs.nixpaks.telegram-desktop}/share/applications/org.telegram.desktop.desktop"
  ]
  ++ lib.optionals config.programs.google-chrome.enable [
    "${pkgs.google-chrome}/share/applications/google-chrome.desktop"
  ];
}
