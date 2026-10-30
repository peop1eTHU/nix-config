{
  pkgs,
  config,
  ...
}:
let
  passwordStoreDir = "${config.xdg.dataHome}/password-store";
in
{
  programs.password-store = {
    enable = true;
    package = pkgs.pass.withExtensions (exts: [
      # support for one-time-password (OTP) tokens
      # NOTE: Saving the password and OTP together runs counter to the purpose of secondary verification!
      # exts.pass-otp

      # exts.pass-import # a generic importer tool from other password managers
      exts.pass-update # an easy flow for updating passwords
    ]);
    # See the “Environment variables” section of pass(1) and the extension man pages for more information about the available keys.
    settings = {
      PASSWORD_STORE_DIR = passwordStoreDir;
      PASSWORD_STORE_CLIP_TIME = "60";
      PASSWORD_STORE_GENERATED_LENGTH = "12";
      PASSWORD_STORE_ENABLE_EXTENSIONS = "true";
    };
  };

  # password-store extensions for browsers
  # you need to install the browser extension for this to work
  # https://github.com/browserpass/browserpass-extension
  programs.browserpass = {
    enable = true;
    browsers = [
      "chrome"
      "chromium"
      "firefox"
    ];
  };
}
