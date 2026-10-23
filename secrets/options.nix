{ secretPlatform }:
{
  config,
  lib,
  myvars,
  ...
}:
let
  cfg = config.modules.secrets;
  isDarwin = secretPlatform == "darwin";
  platform = if isDarwin then "darwin" else "nixos";
  catalog = lib.filterAttrs (_: item: builtins.elem platform (item.platforms or [ "nixos" ])) (
    import ./catalog.nix { inherit myvars; }
  );
  groupDefault = item: lib.any (path: lib.attrByPath path false cfg) item.groups;
in
{
  options.modules.secrets = {
    desktop.enable = lib.mkOption {
      type = lib.types.bool;
      default = isDarwin;
      description = "Default-enable the desktop secret set; individual items can override it.";
    };
    publicKeys.enable = lib.mkEnableOption "Public keys from the secrets repository";
    preservation.enable = lib.mkEnableOption "Use the preserved SSH host identity for decryption";
    items = lib.mapAttrs (name: item: {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = groupDefault item;
        description = "Deploy ${name} from ${item.file}; defaults to its secret group selection.";
      };
    }) catalog;
  }
  // lib.optionalAttrs (!isDarwin) {
    server =
      lib.genAttrs [ "network" "application" "operation" "kubernetes" "webserver" "storage" ]
        (name: {
          enable = lib.mkEnableOption "Default-enable the ${name} server secrets";
        });
  };
}
