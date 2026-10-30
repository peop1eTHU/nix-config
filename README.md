<h2 align="center">:snowflake: Remi's Nix Config :snowflake:</h2>

<p align="center">
  <img src="https://raw.githubusercontent.com/catppuccin/catppuccin/main/assets/palette/macchiato.png" width="400" />
</p>

<p align="center">
	<a href="https://github.com/peop1eTHU/nix-config/stargazers">
		<img alt="Stargazers" src="https://img.shields.io/github/stars/peop1eTHU/nix-config?style=for-the-badge&logo=starship&color=C9CBFF&logoColor=D9E0EE&labelColor=302D41"></a>
    <a href="https://nixos.org/">
        <img src="https://img.shields.io/badge/NixOS-26.11-informational.svg?style=for-the-badge&logo=nixos&color=F2CDCD&logoColor=D9E0EE&labelColor=302D41"></a>
  </a>
</p>

This fork manages Remi's NixOS and macOS configuration. The current personal host is `reminix`, an
aarch64-linux NixOS guest under UTM with Home Manager and Niri.

The inherited desktop, server, MicroVM, and K3s definitions remain as templates. Their hardware and
LAN addresses need review before use. `192.0.2.0/24` and `homelab.example` are reserved examples;
Grafana MCP uses localhost, remote desktop backups and builds are opt-in, and notifications have no
default external recipient. Upstream package and wallpaper downloads remain pinned to the sources
declared in `flake.nix`.

See [./hosts](./hosts) for the host inventory, [./outputs](./outputs) for how the flake outputs are
composed, [./BACKUP.md](./BACKUP.md) for the backup design, and [./AGENTS.md](./AGENTS.md) for the
repository conventions.

## Why NixOS & Flakes?

Nix allows for easy-to-manage, collaborative, reproducible deployments. This means that once
something is setup and configured once, it works (almost) forever. If someone else shares their
configuration, anyone else can just use it (if you really understand what you're copying/referring
now).

For setup and concepts, see [Nix documentation](https://nix.dev/)
and +[nix-darwin](https://github.com/nix-darwin/nix-darwin).

## Components

|                             | NixOS (Wayland)                                                                                                          |
| --------------------------- | ------------------------------------------------------------------------------------------------------------------------ |
| **Display Manager**         | [greetd][greetd] + [tuigreet][tuigreet]                                                                                  |
| **Window Manager**          | [Niri][Niri]                                                                                                             |
| **Desktop Shell**           | [Noctalia][noctalia] — bar/notifications/launcher/lock screen/control center/power menu/screenshots, one native shell    |
| **Terminal Emulators**      | [Kitty][Kitty], [Ghostty][Ghostty]                                                                                       |
| **Terminal Multiplexer**    | [tuios][tuios]                                                                                                           |
| **Shell**                   | [Nushell][Nushell] + [Starship][Starship]                                                                                |
| **Editors / IDE**           | [Zed][Zed] (GUI, primary), VS Code (GUI); [Helix][Helix] (TUI, primary), [Neovim][Neovim] (TUI, backup)                  |
| **Color Scheme**            | [catppuccin-nix][catppuccin-nix]                                                                                         |
| **Networking**              | systemd-networkd / [NetworkManager][NetworkManager]                                                                      |
| **Input Method**            | [Fcitx5][Fcitx5] + [rime][rime] + [小鹤音形 flypy][flypy]                                                                |
| **System Monitor**          | [Btop][Btop] (+ Noctalia's built-in sysmon widgets)                                                                      |
| **File Manager**            | [Yazi][Yazi] (TUI) + [thunar][thunar] (GUI)                                                                              |
| **Media Player**            | [mpv][mpv]                                                                                                               |
| **Image Viewer**            | [imv][imv]                                                                                                               |
| **Screenshots**             | Native Noctalia capture: region / fullscreen / display picker, with a built-in annotation editor                         |
| **Screen Recording**        | [OBS][OBS], gpu-screen-recorder, wf-recorder                                                                             |
| **Fonts**                   | [Nerd fonts][Nerd fonts]                                                                                                 |
| **Filesystem & Encryption** | tmpfs as `/`, [Btrfs][Btrfs] subvolumes on a [LUKS][LUKS] encrypted partition for persistent data; unlock via passphrase |
| **Secure Boot**             | [lanzaboote][lanzaboote]                                                                                                 |

Wallpapers: https://github.com/ryan4yin/wallpapers

## Editors / IDE

- **Terminal editors:** [./home/base/core/editors/](./home/base/core/editors/) — Helix / Neovim,
  `$EDITOR`, docs.
- **GUI editors:** [Zed](./home/base/gui/zed-editor.nix) (primary) and
  [VS Code](./home/linux/gui/base/vscode.nix).
- **LLM coding agents:** [./agents](./agents/) — rules, installers, CLI snippets; see
  [./agents/README.md](./agents/README.md).

## Secrets Management

See [./secrets](./secrets) for details.

## Security & Hardening

See [./SECURITY.md](./SECURITY.md) for the threat model, security architecture, controls and audit
status, [./hardening/README.md](./hardening/README.md) for application sandboxing and Linux
hardening, and [./WORKAROUNDS.md](./WORKAROUNDS.md) for temporary exceptions and known gaps.

## How to Deploy this Flake?

Choose the output for your own host. The inherited configurations contain hardware-specific settings
and optional services that require your own credentials. The private inputs belong to `peop1eTHU`;
`reminix` keeps the optional desktop and server secrets disabled.

Updating flake inputs and rolling the result out safely is a procedure, not a single command. Follow
[`.agents/skills/nix-config-update/SKILL.md`](./.agents/skills/nix-config-update/SKILL.md).

For NixOS:

> To deploy this flake from NixOS's official ISO image (purest installation method), please refer to
> [./nixos-installer/](./nixos-installer)

```bash
# Desktops: deploy the <hostname>-niri nixosConfiguration (e.g. ai-niri, shoukei-niri)
just niri           # equals `sudo nixos-rebuild switch --flake .#<hostname>-niri`
just niri boot      # set as the next boot configuration without switching
just niri switch debug  # detailed output

# Other hosts (servers, VMs): deploy the nixosConfiguration matching the bare hostname
just local
just local boot
just local switch debug
```

For macOS (nix-darwin):

```bash
# If you are deploying for the first time,
# 1. install nix & homebrew manually.
# 2. prepare the deployment environment with essential packages available
nix shell nixpkgs#just nixpkgs#nushell
# 3. comment home-manager's code in lib/macosSystem.nix to speed up the first deployment.

# Deploy the darwinConfiguration by hostname match (fern, frieren)
just local
just local debug  # detailed output (macOS has no switch/boot mode)
```

Remote / cluster hosts are deployed with [Colmena](https://github.com/nix-community/colmena) on top
of the same flake, e.g. `just col <tag>`, `just k3s-test`, `just lab`.

> [What y'all will need when Nix drives you to drink.](https://www.youtube.com/watch?v=Eni9PPPPBpg)
> (copy from hlissner's dotfiles, it really matches my feelings when I first started using NixOS...)

## Validation & Development

`nix develop` provides the formatters and linters used by the repository. The most useful commands:

```bash
just test    # eval tests across Linux & Darwin (fails unless the result is `true`)
just fmt     # format all Nix files with nixfmt
just --list  # all recipes

nix flake check   # broader flake checks
```

For Nix changes, run `just test` and inspect `just fmt`'s diff before committing. Non-Nix files are
formatted with `prettier`; spelling is checked with `typos`.

## References

Other dotfiles that inspired me:

- Nix Flakes
  - [NixOS-CN/NixOS-CN-telegram](https://github.com/NixOS-CN/NixOS-CN-telegram)
  - [notusknot/dotfiles-nix](https://github.com/notusknot/dotfiles-nix)
  - [xddxdd/nixos-config](https://github.com/xddxdd/nixos-config)
  - [bobbbay/dotfiles](https://github.com/bobbbay/dotfiles)
  - [gytis-ivaskevicius/nixfiles](https://github.com/gytis-ivaskevicius/nixfiles)
  - [davidtwco/veritas](https://github.com/davidtwco/veritas)
  - [gvolpe/nix-config](https://github.com/gvolpe/nix-config)
  - [Ruixi-rebirth/flakes](https://github.com/Ruixi-rebirth/flakes)
  - [fufexan/dotfiles](https://github.com/fufexan/dotfiles): gtk theme, xdg, git, media, etc.
  - [nix-community/srvos](https://github.com/nix-community/srvos): a collection of opinionated and
    sharable NixOS configurations for servers
- Modularized NixOS Configuration
  - [hlissner/dotfiles](https://github.com/hlissner/dotfiles)
  - [viperML/dotfiles](https://github.com/viperML/dotfiles)
- Neovim / AstroNvim
  - [maxbrunet/dotfiles](https://github.com/maxbrunet/dotfiles): astronvim with nix flakes.
- Misc
  - [1amSimp1e/dots](https://github.com/1amSimp1e/dots)

[Niri]: https://github.com/YaLTeR/niri
[greetd]: https://github.com/kennylevinsen/greetd
[Kitty]: https://github.com/kovidgoyal/kitty
[Ghostty]: https://github.com/ghostty-org/ghostty
[Nushell]: https://github.com/nushell/nushell
[Starship]: https://github.com/starship/starship
[Fcitx5]: https://github.com/fcitx/fcitx5
[rime]: https://wiki.archlinux.org/title/Rime
[flypy]: https://flypy.cc/
[Btop]: https://github.com/aristocratos/btop
[mpv]: https://github.com/mpv-player/mpv
[tuios]: https://github.com/Gaurav-Gosain/tuios
[Helix]: https://github.com/helix-editor/helix
[Neovim]: https://github.com/neovim/neovim
[Zed]: https://zed.dev
[imv]: https://sr.ht/~exec64/imv/
[OBS]: https://obsproject.com
[Nerd fonts]: https://github.com/ryanoasis/nerd-fonts
[catppuccin-nix]: https://github.com/catppuccin/nix
[NetworkManager]: https://wiki.gnome.org/Projects/NetworkManager
[tuigreet]: https://github.com/apognu/tuigreet
[thunar]: https://gitlab.xfce.org/xfce/thunar
[Yazi]: https://github.com/sxyazi/yazi
[Btrfs]: https://btrfs.readthedocs.io
[LUKS]: https://wiki.archlinux.org/title/Dm-crypt/Encrypting_an_entire_system
[lanzaboote]: https://github.com/nix-community/lanzaboote
[noctalia]: https://github.com/noctalia-dev/noctalia
