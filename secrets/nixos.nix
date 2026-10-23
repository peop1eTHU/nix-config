{ agenix, ... }:
{
  imports = [
    agenix.nixosModules.default
    (import ./options.nix { secretPlatform = "nixos"; })
    (import ./deployment.nix { secretPlatform = "nixos"; })
  ];
}
