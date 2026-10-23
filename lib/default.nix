{ lib, ... }:
rec {
  colmenaSystem = import ./colmenaSystem.nix;
  macosSystem = import ./macosSystem.nix;
  nixosSystem = import ./nixosSystem.nix;

  secretAvailable =
    config: name:
    (config.age.enable or true)
    && builtins.hasAttr name (config.age.secrets or { })
    && (config.age.secrets.${name}.enable or true);

  requireSecretPath =
    {
      config,
      name,
      consumer,
      item ? name,
    }:
    if secretAvailable config name then
      config.age.secrets.${name}.path
    else
      throw "${consumer} requires secret '${name}'; enable modules.secrets.items.\"${item}\".enable or disable the consumer.";

  genK3sServerModule = import ./genK3sServerModule.nix;
  genK3sAgentModule = import ./genK3sAgentModule.nix;
  genVmHostModule = import ./genVmHostModule.nix;
  genMicrovmGuestModule = import ./genMicrovmGuestModule.nix;

  # use path relative to the root of the project
  relativeToRoot = lib.path.append ../.;
  scanPaths =
    path:
    builtins.map (f: (path + "/${f}")) (
      builtins.attrNames (
        lib.attrsets.filterAttrs (
          path: _type:
          (_type == "directory") # include directories
          || (
            (path != "default.nix") # ignore default.nix
            && (lib.strings.hasSuffix ".nix" path) # include .nix files
          )
        ) (builtins.readDir path)
      )
    );
}
