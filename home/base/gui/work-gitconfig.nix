{
  config,
  lib,
  mylib,
  pkgs,
  osConfig ? { },
  darwinConfig ? { },
  ...
}:
let
  systemConfig = if pkgs.stdenv.hostPlatform.isDarwin then darwinConfig else osConfig;
  selected = lib.attrByPath [
    "modules"
    "secrets"
    "items"
    "work-gitconfig"
    "enable"
  ] false systemConfig;
  enabled = selected && mylib.secretAvailable systemConfig "work-gitconfig";
in
{
  # Read the real parent-system switch, not a separately maintained user variable.
  # Git's includeIf rule is harmless when off; no dangling secret link is created.
  home.file."work/.gitconfig" = lib.mkIf enabled {
    source = config.lib.file.mkOutOfStoreSymlink "/etc/agenix/work-gitconfig";
  };
}
