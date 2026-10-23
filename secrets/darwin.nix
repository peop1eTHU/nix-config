{ agenix, ... }:
{
  imports = [
    agenix.darwinModules.default
    (import ./options.nix { secretPlatform = "darwin"; })
    (import ./deployment.nix { secretPlatform = "darwin"; })
  ];
}
