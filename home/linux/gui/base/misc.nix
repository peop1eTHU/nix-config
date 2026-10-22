{
  lib,
  pkgs,
  ...
}:
let
  # The sandboxed wrappers come from overlays that only the hardened hosts
  # import (`hardening/nixpaks`, `hardening/bwraps`); other hosts fall back to
  # the plain nixpkgs build, or skip apps that only ship as a wrapper here.
  hasNixpaks = pkgs ? nixpaks;
  hasBwraps = pkgs ? bwraps;
in
{
  home.packages = with pkgs; [
    # GUI apps
    # e-book viewer(.epub/.mobi/...)
    # do not support .pdf
    foliate

    # remote desktop(rdp connect)
    remmina
    freerdp # required by remmina

    # discord # update too frequently, use the web version instead
  ]
  # my custom hardened packages
  ++ (if hasNixpaks then [ nixpaks.qq nixpaks.telegram-desktop ] else [ telegram-desktop ])
  ++ lib.optionals hasBwraps [ bwraps.wechat ];

  # Fonts install at system level, not user level, so fontconfig does not
  # scan home.packages for them.
  fonts.fontconfig.enable = false;

}
