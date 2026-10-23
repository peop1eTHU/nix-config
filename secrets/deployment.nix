{ secretPlatform }:
{
  config,
  lib,
  pkgs,
  myvars,
  mysecrets,
  agenix,
  mylib,
  ...
}:
let
  cfg = config.modules.secrets;
  isDarwin = secretPlatform == "darwin";
  platform = if isDarwin then "darwin" else "nixos";
  catalog = lib.filterAttrs (_: item: builtins.elem platform (item.platforms or [ "nixos" ])) (
    import ./catalog.nix { inherit myvars; }
  );
  enabled = lib.filterAttrs (name: _: cfg.items.${name}.enable) catalog;
  hasSecrets = enabled != { };
  names = builtins.attrNames enabled;
  resticConflict =
    !isDarwin && cfg.items.desktop-restic-password.enable && cfg.items.homelab-restic-password.enable;
  etcItems = lib.filterAttrs (
    name: item: item ? etc && mylib.secretAvailable config (item.secretName or name)
  ) enabled;
  copyPolicy =
    name: item:
    let
      secret = config.age.secrets.${item.secretName or name};
    in
    {
      # Preserve intentional platform-specific copy modes only for the default
      # secret policy; explicit agenix policy overrides must not be undone.
      mode = if secret.mode == item.policy.mode then item.etc.mode or secret.mode else secret.mode;
      user = secret.owner;
    };
  serverEnabled = !isDarwin && lib.any (group: group.enable) (builtins.attrValues cfg.server);
in
{
  config = lib.mkMerge (
    [
      {
        assertions = [
          {
            assertion = !(cfg.desktop.enable && serverEnabled);
            message = "Enable either the desktop or server secret group defaults, not both.";
          }
          {
            assertion = !resticConflict;
            message = "desktop-restic-password and homelab-restic-password cannot both supply restic-password.";
          }
        ];
      }
      (lib.mkIf hasSecrets {
        environment.systemPackages = [ agenix.packages.${pkgs.stdenv.hostPlatform.system}.default ];
        age.identityPaths = lib.mkDefault [
          (
            if !isDarwin && cfg.preservation.enable then
              "/persistent/etc/ssh/ssh_host_ed25519_key"
            else
              "/etc/ssh/ssh_host_ed25519_key"
          )
        ];
        # Check duplicate runtime names before constructing the attribute set, rather
        # than letting listToAttrs silently choose one of two different passwords.
        age.secrets =
          if resticConflict then
            throw "Conflicting desktop/homelab restic-password sources; disable one modules.secrets.items entry."
          else
            lib.listToAttrs (
              map (
                name:
                let
                  item = enabled.${name};
                in
                lib.nameValuePair (item.secretName or name) (
                  {
                    file = "${mysecrets}/${item.file}";
                  }
                  // item.policy
                )
              ) names
            );
        environment.etc = lib.mapAttrs' (
          name: item:
          lib.nameValuePair "agenix/${item.etc.name}" (
            {
              source = config.age.secrets.${item.secretName or name}.path;
            }
            // lib.optionalAttrs (!isDarwin && item.etc ? mode) (copyPolicy name item)
          )
        ) etcItems;
      })
    ]
    ++ lib.optionals isDarwin [
      (lib.mkIf (hasSecrets && (config.age.enable or true)) {
        launchd.daemons."activate-agenix".serviceConfig = {
          StandardErrorPath = "/Library/Logs/org.nixos.activate-agenix.stderr.log";
          StandardOutPath = "/Library/Logs/org.nixos.activate-agenix.stdout.log";
        };
        # nix-darwin ignores environment.etc mode/owner. Touch only the enabled
        # mappings and preserve their old Darwin policy; do not chown the directory.
        system.activationScripts.postActivation.text = lib.concatStringsSep "\n" (
          lib.mapAttrsToList (
            name: item:
            let
              path = "/etc/agenix/${item.etc.name}";
              secret = config.age.secrets.${item.secretName or name};
            in
            ''
              ${pkgs.coreutils}/bin/chown ${lib.escapeShellArg secret.owner} ${lib.escapeShellArg path}
              ${pkgs.coreutils}/bin/chmod ${secret.mode} ${lib.escapeShellArg path}
            ''
          ) etcItems
        );
      })
    ]
  );
}
