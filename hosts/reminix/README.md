# Reminix

NixOS aarch64 guest running under UTM on an Apple Silicon Mac, with the QEMU backend and
`virtio-gpu-gl-pci` for OpenGL acceleration (niri needs it).

- 8 GiB RAM, 6 vCPUs, 64 GiB virtio disk (`/dev/vda`), UEFI boot
- Host name and flake output name are both `reminix`; deploy with `just local` or
  `sudo nixos-rebuild switch --flake .#reminix`.
- Secrets: `secrets/nixos.nix` is imported, but every group is off
  (`modules.secrets.*.enable = false`), so no agenix secret decrypts yet.

## Install

1. Boot the guest from the NixOS 26.05 minimal aarch64 ISO attached to UTM's CD drive.
2. Get this flake into the installer. Either clone it as `remi`:

   ```sh
   git clone git@github.com:peop1eTHU/nix-config.git ~/nix-config
   cd ~/nix-config
   ```

   or share it through UTM (`Sharing` → the checkout directory) and copy it.

3. Put the agenix host key in place _before_ installing, so the first boot can decrypt
   `/run/agenix/nix-access-tokens` once the secrets group is turned on. The identity is
   `~/Documents/nix-secrets/reminix_host_ed25519` on the Mac; the matching `.pub` is a recipient in
   that repo's `secrets.nix`.

4. Partition and install:

   ```sh
   sudo nix --experimental-features "nix-command flakes" run github:nix-community/disko \
     -- --mode destroy,format,mount --yes-wipe-all-disks hosts/reminix/disko-fs.nix

   sudo nixos-install --root /mnt --flake .#reminix --no-root-password --show-trace \
     --option substituters "https://mirrors.sjtug.sjtu.edu.cn/nix-channels/store https://mirrors.ustc.edu.cn/nix-channels/store https://mirror.nju.edu.cn/nix-channels/store https://cache.nixos.org"
   ```

5. `reboot`, log in as `remi` with the bootstrap password from `vars/default.nix`, then change it
   with `passwd`.

## Validate before installing

```sh
just eval-host reminix
just build-host reminix   # needs an aarch64 builder or the guest itself
```

## 桌面与图形加速

共享 niri 配置必须包含 `niri-hardware.kdl`，由本机 Home
Manager 配置部署；缺少它会导致 niri 使用默认配置，Noctalia 不会自动启动。

UTM 5.0.8 的默认 ANGLE Metal 后端在这台机器上提供桌面 OpenGL 2.1。正常关机后，在
**UTM 应用设置 → 显示 → QEMU 图形加速 → 渲染器后端** 选择 **Apple 核心 OpenGL**，虚拟机显卡保持
`virtio-gpu-gl-pci`。该后端官方支持 OpenGL
4.1，不支持 Vulkan/DirectX；这是应用级偏好，会影响其他 QEMU 虚拟机。若有显示问题，关机后恢复默认后端。

Kitty 保持硬件渲染。Ghostty 1.3.1 要求 OpenGL 4.3，所以本机只对 Ghostty 设置
`LIBGL_ALWAYS_SOFTWARE=1`，不影响 niri 或其他程序。不要使用版本覆盖变量虚报 OpenGL 能力。检查实际版本：

```sh
eglinfo -B
niri validate
```

窗口获得焦点后，用 `Command+Option` 捕获/释放 UTM 输入。捕获时 Command 对应 Super：`Command+Return`
启动 Ghostty，`Command+Shift+Return` 启动 Kitty，`Command+D` / `Command+Space`
打开 Noctalia 启动器。

防火墙仅额外允许 Mac 的 UTM 网关 `192.168.64.1` 访问 TCP
22，SSH 仍只接受公钥。网关变化时必须同步调整本机规则，而不是关闭防火墙。

更新本机配置时用实际输出名 `reminix`，不要使用面向 `*-niri` 输出的 `just niri`：

```sh
cd ~/nix-config
git pull --ff-only
# 只构建不激活，先确认能通过：
nixos-rebuild build --flake .#reminix
# 构建、登记为新的系统代数、更新启动项并立即切换：
sudo nixos-rebuild switch --flake .#reminix
# 出问题时回到上一代：
sudo nixos-rebuild switch --rollback
```

不要用 `./result/bin/switch-to-configuration switch` 代替：它只切换当前运行的系统，不会把新系统写入
`/nix/var/nix/profiles/system`，重启后会回到旧的一代。

## 单独启用工作 Git 身份 secret

本机默认不启用任何 age secret。真实工作身份密文准备好并提交到私有仓库、更新 `mysecrets` 锁后，可以在
`hosts/reminix/default.nix` 设置：

```nix
modules.secrets.items."work-gitconfig".enable = true;
```

不需要打开 `desktop.enable`；这只投放 `/etc/agenix/work-gitconfig` 并链接到
`~/work/.gitconfig`，不会读取作者的其他桌面凭据。禁用时不创建该链接，Git 回到默认个人身份；仓库本地的 user.name/user.email 仍可覆盖。现在没有设置这个开关，也没有创建密文。

## Notes

- `boot.loader.grub.device` from `modules/nixos/server/qemu-guest.nix` is overridden by
  `boot.loader.systemd-boot` in `hosts/reminix/default.nix`; UTM boots through UEFI, so the GRUB
  path is unused.
- `lanzaboote`, `preservation`, `nixpaks`/`bwraps` and Colmena are deliberately not imported for
  this host. The modules stay in the tree for future machines.
