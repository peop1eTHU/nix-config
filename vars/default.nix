{ lib }:
{
  username = "remi";
  userfullname = "Remi";
  useremail = "cqq060213@163.com";
  networking = import ./networking.nix { inherit lib; };
  # Home-manager modules cannot see the NixOS `modules.secrets.*` options, so the
  # switches they need are mirrored here. Keep them in step with
  # `outputs/<system>/src/<host>.nix`; `secrets.publicKeys.enable` there is the
  # NixOS-side option that gates the same files.
  secrets.publicKeys.enable = false;
  # Temporary bootstrap password; rotate it with `passwd` after the first login.
  # Generated using: openssl passwd -6 -salt reminix 123456
  # https://man.archlinux.org/man/crypt.5.en
  initialHashedPassword = "$6$reminix$JUQ0C3p7EWu3LtRFp5PnE7KPMBF6w2Z8cfINh64tUyfFb3QIey3pzo9Z4Y9U.AHsT5TbWm5lOvKXDkDfbzb3N/";
  # Public Keys that can be used to login to all my PCs, Macbooks, and servers.
  #
  # Since its authority is so large, we must strengthen its security:
  # 1. The corresponding private key must be:
  #    1. Generated locally on every trusted client via:
  #      ```bash
  #      # KDF: bcrypt with 256 rounds, takes 2s on Apple M2):
  #      # Passphrase: digits + letters + symbols, 12+ chars
  #      ssh-keygen -t ed25519 -a 256 -C "ryan@xxx" -f ~/.ssh/xxx
  #      ```
  #    2. Never leave the device and never sent over the network.
  # 2. Or just use hardware security keys like Yubikey/CanoKey.
  mainSshAuthorizedKeys = [
    # The main ssh key for daily usage (MacBook, the host that runs the UTM VM)
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFOcJoNIw0pXencMB+ItHPIbrFyj+UvMa5odR2v8mpKW jyxc-dz-0101390@JYXC-DZ-0101390deMacBook-Pro.local"
  ];
  secondaryAuthorizedKeys = [
    # the backup ssh keys for disaster recovery
  ];
  # The SSH host keys of the machines whose nix-daemons build through aquamarine
  # (modules/nixos/base/remote-builders.nix).
  remoteBuilderClientKeys = [ ];
}
