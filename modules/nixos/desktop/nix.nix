{
  config,
  lib,
  mylib,
  ...
}:
{
  # The token file only exists when a secrets group is on (secrets/nixos.nix);
  # hosts that run without secrets skip the include instead of failing to eval.
  nix.extraOptions = lib.mkIf (mylib.secretAvailable config "nix-access-tokens") ''
    # decrypted secret: AI agents must not read it
    !include ${config.age.secrets.nix-access-tokens.path}
  '';
}
