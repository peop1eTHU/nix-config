{ outputs, myvars, ... }:
let
  cfg = outputs.nixosConfigurations.reminix.config;
  hm = cfg.home-manager.users.${myvars.username};
  voice = builtins.fromJSON (builtins.readFile ../../../../home/linux/gui/base/vinput/config.json);
  whisper = builtins.head (
    builtins.filter (provider: provider.id == voice.asr.active_provider) voice.asr.providers
  );
in
{
  customCaCount = builtins.length cfg.security.pki.certificateFiles;
  remoteBuildsEnabled = cfg.nix.distributedBuilds;
  backupsEnabled = cfg.modules.restic-backup.enable;
  backupNotifiesExternally = cfg.modules.restic-backup.alertManagerUrl != null;
  passwordRecipientOverride = hm.programs.password-store.settings ? PASSWORD_STORE_KEY;
  passwordSigningOverride = hm.programs.password-store.settings ? PASSWORD_STORE_SIGNING_KEY;
  inheritsBuilderHostKeys =
    cfg.programs.ssh.knownHosts ? aquamarine || cfg.programs.ssh.knownHosts ? youko;
  voiceAsrEndpoint = whisper.env.VINPUT_ASR_URL;
  voiceCorrectionScene = voice.scenes.active_scene;
  homelabLan = myvars.networking.lanCidr;
  voiceCorrectionEndpoint =
    (builtins.head (builtins.filter (provider: provider.id == "llama-swap") voice.llm.providers))
    .base_url;
}
