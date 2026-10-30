{ lib, myvars, ... }:
let
  # Evaluate policy without real packages, ciphertext, network or decryption.
  stub = { lib, ... }: {
    options = {
      age.enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
      };
      assertions = lib.mkOption {
        type = lib.types.listOf lib.types.attrs;
        default = [ ];
      };
      age.secrets = lib.mkOption {
        type = lib.types.attrsOf (
          lib.types.submodule (
            { name, ... }: {
              freeformType = lib.types.attrs;
              options.enable = lib.mkOption {
                type = lib.types.bool;
                default = true;
              };
              options.owner = lib.mkOption { type = lib.types.str; };
              options.mode = lib.mkOption { type = lib.types.str; };
              options.path = lib.mkOption {
                type = lib.types.str;
                default = "/run/agenix/${name}";
              };
            }
          )
        );
        default = { };
      };
      age.identityPaths = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
      };
      environment.systemPackages = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
      };
      environment.etc = lib.mkOption {
        type = lib.types.attrs;
        default = { };
      };
      launchd.daemons = lib.mkOption {
        type = lib.types.attrs;
        default = { };
      };
      system.activationScripts = lib.mkOption {
        type = lib.types.attrs;
        default = { };
      };
    };
  };
  eval =
    darwin: selection:
    (lib.evalModules {
      modules = [
        stub
        (import ../secrets/options.nix { secretPlatform = if darwin then "darwin" else "nixos"; })
        (import ../secrets/deployment.nix { secretPlatform = if darwin then "darwin" else "nixos"; })
        selection
      ];
      specialArgs = {
        inherit myvars mylib;
        mysecrets = "/test-ciphertext-only";
        pkgs = {
          stdenv.hostPlatform = {
            isDarwin = darwin;
            system = if darwin then "aarch64-darwin" else "aarch64-linux";
          };
          coreutils = "/test-coreutils";
        };
        agenix.packages = {
          aarch64-linux.default = "/test-agenix-linux";
          aarch64-darwin.default = "/test-agenix-darwin";
        };
      };
    }).config;
  group = path: eval false { modules.secrets = lib.setAttrByPath path true; };
  none = eval false { };
  work = eval false { modules.secrets.items.work-gitconfig.enable = true; };
  desktop = group [
    "desktop"
    "enable"
  ];
  disabledRclone = eval false {
    modules.secrets.desktop.enable = true;
    modules.secrets.items."rclone.conf".enable = false;
  };
  disabledToken = eval false {
    modules.secrets.desktop.enable = true;
    modules.secrets.items.nix-access-tokens.enable = false;
  };
  preserved = eval false {
    modules.secrets.items.work-gitconfig.enable = true;
    modules.secrets.preservation.enable = true;
  };
  nativeOff = eval false {
    modules.secrets.items.work-gitconfig.enable = true;
    age.secrets.work-gitconfig.enable = false;
  };
  ageOff = eval false {
    modules.secrets.items.work-gitconfig.enable = true;
    age.enable = false;
  };
  macNativeOff = eval true {
    modules.secrets.desktop.enable = false;
    modules.secrets.items.work-gitconfig.enable = true;
    age.secrets.work-gitconfig.enable = false;
  };
  macAgeOff = eval true {
    modules.secrets.desktop.enable = false;
    modules.secrets.items.work-gitconfig.enable = true;
    age.enable = false;
  };
  macPolicy = eval true {
    modules.secrets.desktop.enable = false;
    modules.secrets.items.work-gitconfig.enable = true;
    age.secrets.work-gitconfig.owner = lib.mkForce "root";
    age.secrets.work-gitconfig.mode = lib.mkForce "0400";
  };
  linuxPolicy = eval false {
    modules.secrets.items.work-gitconfig.enable = true;
    age.secrets.work-gitconfig.owner = lib.mkForce "root";
    age.secrets.work-gitconfig.mode = lib.mkForce "0000";
  };
  mac = eval true { };
  macNone = eval true { modules.secrets.desktop.enable = false; };
  macWork = eval true {
    modules.secrets.desktop.enable = false;
    modules.secrets.items.work-gitconfig.enable = true;
  };
  catalog = import ../secrets/catalog.nix { inherit myvars; };
  itemCases = lib.mapAttrs (
    name: item:
    let
      cfg = eval false { modules.secrets.items.${name}.enable = true; };
    in
    builtins.attrNames cfg.age.secrets == [ (item.secretName or name) ]
    && cfg.age.secrets.${item.secretName or name}.file == "/test-ciphertext-only/${item.file}"
    && cfg.age.secrets.${item.secretName or name}.mode == item.policy.mode
    && cfg.age.secrets.${item.secretName or name}.owner == item.policy.owner
  ) catalog;
  mylib = import ../lib { inherit lib; };
  rejected = value: !(builtins.tryEval (builtins.deepSeq value true)).success;
  workLink =
    darwin: enabled:
    (lib.evalModules {
      modules = [
        ({ lib, ... }: {
          options.home.file = lib.mkOption {
            type = lib.types.attrsOf (
              lib.types.submodule { options.source = lib.mkOption { type = lib.types.str; }; }
            );
            default = { };
          };
          options.lib = lib.mkOption {
            type = lib.types.attrs;
            default = { };
          };
          config.lib.file.mkOutOfStoreSymlink = path: path;
        })
        ../home/base/gui/work-gitconfig.nix
      ];
      specialArgs = {
        inherit lib mylib;
        pkgs.stdenv.hostPlatform.isDarwin = darwin;
        osConfig = {
          modules.secrets.items.work-gitconfig.enable = !darwin && enabled;
          age.secrets.work-gitconfig.enable = enabled;
        };
        darwinConfig = {
          modules.secrets.items.work-gitconfig.enable = darwin && enabled;
          age.secrets.work-gitconfig.enable = enabled;
        };
      };
    }).config.home.file;
  darwinToken =
    enabled:
    (lib.evalModules {
      modules = [
        ({ lib, ... }: {
          options = {
            nix.extraOptions = lib.mkOption {
              type = lib.types.lines;
              default = "";
            };
            nix.enable = lib.mkOption { type = lib.types.bool; };
            nix.gc.automatic = lib.mkOption { type = lib.types.bool; };
            system.stateVersion = lib.mkOption { type = lib.types.int; };
          };
        })
        ../modules/darwin/nix-core.nix
      ];
      specialArgs = {
        inherit mylib;
        config.age.secrets = lib.optionalAttrs enabled { nix-access-tokens.path = "/test-token"; };
      };
    }).config.nix;
in
{
  workLinkGate =
    lib.all
      (
        darwin:
        workLink darwin false == { }
        && (workLink darwin true)."work/.gitconfig".source == "/etc/agenix/work-gitconfig"
      )
      [
        false
        true
      ];
  darwinTokenGate =
    (darwinToken false).extraOptions == ""
    && lib.hasInfix "/test-token" (darwinToken true).extraOptions;
  nativeDisable =
    nativeOff.environment.etc == { }
    && ageOff.environment.etc == { }
    && rejected (
      mylib.requireSecretPath {
        config = nativeOff;
        name = "work-gitconfig";
        consumer = "Git";
      }
    )
    && rejected (
      mylib.requireSecretPath {
        config = ageOff;
        name = "work-gitconfig";
        consumer = "Git";
      }
    )
    && macNativeOff.system.activationScripts.postActivation.text == ""
    && macAgeOff.launchd.daemons == { }
    && macAgeOff.system.activationScripts == { };
  effectivePolicy =
    lib.hasInfix "chown root" macPolicy.system.activationScripts.postActivation.text
    && lib.hasInfix "chmod 0400" macPolicy.system.activationScripts.postActivation.text
    && linuxPolicy.environment.etc."agenix/work-gitconfig".user == "root"
    && linuxPolicy.environment.etc."agenix/work-gitconfig".mode == "0000";
  allItemCases = lib.all (x: x) (builtins.attrValues itemCases);
  allDisabled = none.age.secrets == { } && none.environment.etc == { };
  workOnly =
    builtins.attrNames work.age.secrets == [ "work-gitconfig" ]
    && work.environment.etc."agenix/work-gitconfig".mode == "0400"
    && work.environment.etc."agenix/work-gitconfig".user == myvars.username;
  desktopDefaults =
    builtins.attrNames desktop.age.secrets == [
      "nix-access-tokens"
      "rclone.conf"
      "restic-password"
      "restic-rest-credentials"
      "ssh-key-romantic"
      "work-gitconfig"
    ];
  overrideGroup =
    !(disabledRclone.age.secrets ? "rclone.conf")
    && !(disabledRclone.environment.etc ? "agenix/rclone.conf")
    && !(disabledToken.age.secrets ? nix-access-tokens);
  serverDefaults =
    lib.all
      (
        entry:
        builtins.attrNames
          (group [
            "server"
            entry.group
            "enable"
          ]).age.secrets == entry.names
      )
      [
        {
          group = "network";
          names = [ "nix-access-tokens" ];
        }
        {
          group = "application";
          names = [
            "nix-access-tokens"
            "rustfs.env"
            "sftpgo.env"
            "transmission-credentials.json"
          ];
        }
        {
          group = "operation";
          names = [
            "alertmanager.env"
            "grafana-admin-password"
            "grafana-secret-key"
            "nix-access-tokens"
          ];
        }
        {
          group = "kubernetes";
          names = [
            "k3s-test-1-token"
            "nix-access-tokens"
          ];
        }
        {
          group = "webserver";
          names = [
            "cloudflare-dns-api-token"
            "nix-access-tokens"
            "postgres-ecc-server.key"
          ];
        }
        {
          group = "storage";
          names = [
            "hdd-luks-crypt-key"
            "nix-access-tokens"
            "restic-password"
            "restic-rest-htpasswd"
          ];
        }
      ];
  resticSources =
    (eval false { modules.secrets.items.desktop-restic-password.enable = true; })
    .age.secrets.restic-password.file == "/test-ciphertext-only/desktop/restic-password-desktop.age"
    &&
      (eval false { modules.secrets.items.homelab-restic-password.enable = true; })
      .age.secrets.restic-password.file == "/test-ciphertext-only/server/restic-password-homelab.age";
  resticConflict =
    rejected
      (eval false {
        modules.secrets.items.desktop-restic-password.enable = true;
        modules.secrets.items.homelab-restic-password.enable = true;
      }).age.secrets;
  groupConflict =
    !(lib.all (x: x.assertion)
      (eval false {
        modules.secrets.desktop.enable = true;
        modules.secrets.server.network.enable = true;
      }).assertions
    );
  identity =
    preserved.age.identityPaths == [ "/persistent/etc/ssh/ssh_host_ed25519_key" ]
    && work.age.identityPaths == [ "/etc/ssh/ssh_host_ed25519_key" ];
  darwinDefaults =
    builtins.attrNames mac.age.secrets == [
      "nix-access-tokens"
      "rclone.conf"
      "ssh-key-romantic"
      "work-gitconfig"
    ];
  darwinOff =
    macNone.age.secrets == { }
    && macNone.environment.etc == { }
    && macNone.system.activationScripts == { };
  darwinWorkOnly =
    builtins.attrNames macWork.age.secrets == [ "work-gitconfig" ]
    && !(lib.hasInfix "rclone" macWork.system.activationScripts.postActivation.text)
    && lib.hasInfix "chmod 0500" macWork.system.activationScripts.postActivation.text;
  requiredConsumer = rejected (
    mylib.requireSecretPath {
      config = none;
      name = "grafana-secret-key";
      consumer = "Grafana";
    }
  );
  enabledConsumer =
    mylib.requireSecretPath {
      config = work;
      name = "work-gitconfig";
      consumer = "Git";
    } == "/run/agenix/work-gitconfig";
}
