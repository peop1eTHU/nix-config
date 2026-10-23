{
  inputs,
  lib,
  myvars,
  ...
}:
let
  outputs = inputs.self;
  work = outputs.nixosConfigurations.reminix.extendModules {
    modules = [ { modules.secrets.items.work-gitconfig.enable = true; } ];
  };
  base = outputs.nixosConfigurations.reminix.config;
  rustOff = outputs.nixosConfigurations.youko.extendModules {
    modules = [ { modules.secrets.items."rustfs.env".enable = false; } ];
  };
  rustServiceOff = outputs.nixosConfigurations.youko.extendModules {
    modules = [
      {
        modules.secrets.items."rustfs.env".enable = false;
        services.rustfs.enable = lib.mkForce false;
      }
    ];
  };
  k3sOff = outputs.nixosConfigurations.k3s-test-1-worker-1.extendModules {
    modules = [ { modules.secrets.items.k3s-test-1-token.enable = false; } ];
  };
  k3sServiceOff = outputs.nixosConfigurations.k3s-test-1-worker-1.extendModules {
    modules = [
      {
        modules.secrets.items.k3s-test-1-token.enable = false;
        services.k3s.enable = lib.mkForce false;
      }
    ];
  };
  luksOff = outputs.nixosConfigurations.youko.extendModules {
    modules = [ { modules.secrets.items.hdd-luks-crypt-key.enable = false; } ];
  };
  rejected = value: !(builtins.tryEval (builtins.deepSeq value true)).success;
  cfg = work.config;
in
{
  baseHasNoSecrets = base.age.secrets == { };
  baseHasNoWorkLink = !(base.home-manager.users.${myvars.username}.home.file ? "work/.gitconfig");
  workOnly = builtins.attrNames cfg.age.secrets == [ "work-gitconfig" ];
  workPermissions =
    cfg.age.secrets.work-gitconfig.owner == myvars.username
    && cfg.environment.etc."agenix/work-gitconfig".user == myvars.username
    && cfg.environment.etc."agenix/work-gitconfig".mode == "0400";
  workLinkPresent = cfg.home-manager.users.${myvars.username}.home.file ? "work/.gitconfig";
  noImplicitToken = !(lib.hasInfix "!include" cfg.nix.extraOptions);
  missingRustfsRejected = rejected rustOff.config.services.rustfs.environmentFile;
  disabledRustfsSkipsSecret =
    rustServiceOff.options.services.rustfs.environmentFile.definitions == [ ];
  missingK3sRejected = rejected k3sOff.config.services.k3s.tokenFile;
  disabledK3sSkipsSecret = k3sServiceOff.config.services.k3s.tokenFile == null;
  missingLuksRejected = !(lib.all (entry: entry.assertion) luksOff.config.assertions);
}
