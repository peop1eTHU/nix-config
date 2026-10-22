{
  disko,
  mylib,
  lib,
  ...
}:
#############################################################
#
#  Reminix - NixOS guest under UTM (QEMU, virtio-gpu-gl) on an Apple Silicon Mac
#
#############################################################
let
  hostName = "reminix"; # Define your hostname.
in
{
  imports = [
    ./disko-fs.nix
    disko.nixosModules.default
  ];

  # supported file systems, so we can mount any removable disks with these filesystems
  boot.supportedFilesystems = [
    "ext4"
    "btrfs"
    "xfs"
    "ntfs"
    "fat"
    "vfat"
    "exfat"

    # for file sharing between host & guests
    "virtiofs"
  ];

  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "virtio_pci"
    "usbhid"
    "usb_storage"
    "sr_mod"
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  # UTM boots the guest through UEFI, so systemd-boot is the only loader that
  # can be installed from the live ISO without an MBR.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # 8G guest RAM; keep zram small since the host has 16G and holds the page cache
  # for the virtio disk anyway.
  zramSwap.memoryPercent = lib.mkDefault 50;

  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";

  networking = {
    inherit hostName;

    networkmanager.enable = true;

    # Shared firewall trusts the upstream LAN, not UTM's host-only gateway.
    # Allow key-authenticated SSH from this Mac without opening the whole subnet.
    firewall.extraInputRules = ''
      ip saddr 192.168.64.1 tcp dport 22 accept
    '';
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "26.05"; # Did you read the comment?
}
