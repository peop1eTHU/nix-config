# Reminix

NixOS aarch64 guest running under UTM on an Apple Silicon Mac, with the QEMU
backend and `virtio-gpu-gl-pci` for OpenGL acceleration (niri needs it).

- 8 GiB RAM, 6 vCPUs, 64 GiB virtio disk (`/dev/vda`), UEFI boot
- Host name and flake output name are both `reminix`, so `just niri`-style
  deployment and the `hostname` eval test need no special case.
- Secrets: `secrets/nixos.nix` is imported, but every group is off
  (`modules.secrets.*.enable = false`), so no agenix secret decrypts yet.

## Install

1. Boot the guest from the NixOS 26.05 minimal aarch64 ISO attached to UTM's
   CD drive.
2. Get this flake into the installer. Either clone it as `remi`:

   ```sh
   git clone git@github.com:peop1eTHU/nix-config.git ~/nix-config
   cd ~/nix-config
   ```

   or share it through UTM (`Sharing` → the checkout directory) and copy it.

3. Put the agenix host key in place *before* installing, so the first boot can
   decrypt `/run/agenix/nix-access-tokens` once the secrets group is turned on.
   The identity is `~/Documents/nix-secrets/reminix_host_ed25519` on the Mac;
   the matching `.pub` is a recipient in that repo's `secrets.nix`.

4. Partition and install:

   ```sh
   sudo nix --experimental-features "nix-command flakes" run github:nix-community/disko \
     -- --mode destroy,format,mount --yes-wipe-all-disks hosts/reminix/disko-fs.nix

   sudo nixos-install --root /mnt --flake .#reminix --no-root-password --show-trace \
     --option substituters "https://mirrors.sjtug.sjtu.edu.cn/nix-channels/store https://mirrors.ustc.edu.cn/nix-channels/store https://mirror.nju.edu.cn/nix-channels/store https://cache.nixos.org"
   ```

5. `reboot`, log in as `remi` with the bootstrap password from
   `vars/default.nix`, then change it with `passwd`.

## Validate before installing

```sh
just eval-host reminix
just build-host reminix   # needs an aarch64 builder or the guest itself
```

## Notes

- `boot.loader.grub.device` from `modules/nixos/server/qemu-guest.nix` is
  overridden by `boot.loader.systemd-boot` in `hosts/reminix/default.nix`; UTM
  boots through UEFI, so the GRUB path is unused.
- `lanzaboote`, `preservation`, `nixpaks`/`bwraps` and Colmena are deliberately
  not imported for this host. The modules stay in the tree for future machines.
