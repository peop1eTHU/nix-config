{ outputs, ... }:
let
  cfg = outputs.nixosConfigurations.youko.config;
in
{
  desktopRemoteBuilds = outputs.nixosConfigurations.ai-niri.config.modules.remote-builders.enable;
  desktopRemoteBackups = outputs.nixosConfigurations.ai-niri.config.modules.restic-backup.enable;
  telegramRecipient = cfg.modules.homelab.telegramChatId;
  alertReceivers = map (
    receiver: receiver.name
  ) cfg.services.prometheus.alertmanager.configuration.receivers;
  alertCredentialFile = cfg.services.prometheus.alertmanager.environmentFile;
  backupNotifierExists = cfg.systemd.services ? restic-backup-notify;
  caddyEnabled = cfg.services.caddy.enable;
}
