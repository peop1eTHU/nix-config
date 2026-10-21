{
  # NOTE: the args not used in this file CAN NOT be removed!
  # because haumea pass argument lazily,
  # and these arguments are used in the functions like `mylib.nixosSystem`, `mylib.colmenaSystem`, etc.
  inputs,
  lib,
  myvars,
  mylib,
  system,
  genSpecialArgs,
  ...
}@args:
let
  name = "reminix";
  base-modules = {
    nixos-modules =
      (map mylib.relativeToRoot [
        # common
        "secrets/nixos.nix"
        "modules/nixos/desktop.nix"
        "modules/nixos/server/qemu-guest.nix"
        # host specific
        "hosts/${name}"
      ])
      ++ [
        {
          modules.desktop.fonts.enable = true;
          modules.desktop.wayland.enable = true;
          programs.niri.enable = true;

          # cache.nixos.org is effectively unreachable from this network, so take
          # the binary cache from the mainland mirrors instead.
          modules.nix.mirrors.enable = true;

          # Opted out on this host; the modules stay in the tree for future hosts.
          modules.desktop.canokey.enable = false;
          modules.desktop.gaming.enable = false;
          modules.networking.mihomo.enable = false;
          modules.secrets.desktop.enable = false;
          modules.secrets.server.application.enable = false;
          modules.secrets.server.network.enable = false;
          modules.secrets.server.operation.enable = false;
          modules.secrets.preservation.enable = false;
          modules.secrets.publicKeys.enable = false;
        }
      ];
    home-modules = map mylib.relativeToRoot [
      "home/hosts/linux/${name}.nix"
    ];
  };
in
{
  nixosConfigurations = {
    ${name} = mylib.nixosSystem (base-modules // args);
  };

  # ISO for reinstalling this guest without a separate installer host.
  packages = {
    ${name} = inputs.self.nixosConfigurations.${name}.config.system.build.images.iso;
  };
}
