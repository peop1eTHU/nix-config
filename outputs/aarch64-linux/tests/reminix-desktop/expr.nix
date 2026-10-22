{
  outputs,
  myvars,
  lib,
  ...
}:
let
  cfg = outputs.nixosConfigurations.reminix.config;
  hm = cfg.home-manager.users.${myvars.username};
  firewall = cfg.networking.firewall;
in
{
  niriEnabled = cfg.programs.niri.enable && hm.modules.desktop.niri.enable;
  hardwareIncludePresent = builtins.pathExists hm.xdg.configFile."niri/niri-hardware.kdl".source;
  ghosttyPackage = hm.programs.ghostty.package.name;
  ghosttyMainProgram = hm.programs.ghostty.package.meta.mainProgram;
  kittyPackage = hm.programs.kitty.package.pname;
  noGlobalSoftwareRendering =
    !(cfg.environment.sessionVariables ? LIBGL_ALWAYS_SOFTWARE)
    && !(hm.home.sessionVariables ? LIBGL_ALWAYS_SOFTWARE);
  hostSshRule = lib.hasInfix "ip saddr 192.168.64.1 tcp dport 22 accept" firewall.extraInputRules;
  firewallEnabled = firewall.enable;
  noGlobalOpenPorts = firewall.allowedTCPPorts == [ ] && firewall.allowedUDPPorts == [ ];
  passwordAuthentication = cfg.services.openssh.settings.PasswordAuthentication;
}
