# Rime customisation

Personal Rime setup shared by fcitx5-rime (Linux) and Squirrel (macOS) so both behave the same. The
schema set is chosen by `modules.desktop.rime.schema` in `default.nix`:

| Value              | Schemas                                                               | Personal files                         |
| ------------------ | --------------------------------------------------------------------- | -------------------------------------- |
| `jidian` (default) | 86 wubi (极点五笔): `wubi86_jidian_pinyin` first, then `wubi86_jidian`, `pinyin_simp` | `jidian.custom.yaml`                   |
| `flypy`            | [flypy](https://flypy.com/) (小鹤音形)                                | `flypy.custom.yaml`, `flypy_user.txt` |

Switch a host back to flypy with `modules.desktop.rime.schema = "flypy";` in its Home Manager
config.

## Files

- `jidian.custom.yaml`: preferences for the jidian schemas, deployed as both
  `wubi86_jidian_pinyin.custom.yaml` and `wubi86_jidian.custom.yaml`.
- `flypy.custom.yaml`: the same preferences for flypy.
- `flypy_user.txt`: the flypy user dictionary (custom phrases, symbols, missing characters).
- `default.nix`: the schema option, the jidian package, and per-platform wiring.

The jidian data is built from [KyleBing/rime-wubi86-jidian](https://github.com/KyleBing/rime-wubi86-jidian)
(Apache-2.0) at a pinned commit: only its `*.schema.yaml` and `*.dict.yaml`, plus Rime's prelude
(`default.yaml`, `key_bindings.yaml`, `punctuation.yaml`, `symbols.yaml`) from nixpkgs' `rime-data`,
and a `default.custom.yaml` that puts `wubi86_jidian_pinyin` first. Upstream's `default`,
`squirrel` and `weasel` customs are not installed. The flypy data comes from the `rime-data-flypy`
package in `nur-ryan4yin`. Both stay untouched, so updates survive. On macOS the flypy shared data
includes an empty `flypy_user.txt`, so the user files set `home.fileOverlapResolution = "override"`
to win over it.

In `wubi86_jidian_pinyin` a code is looked up as wubi and pinyin at the same time; in every jidian
schema, typing `z` first reverse-looks up a character by pinyin and shows its wubi code.

## Preferences

Both custom files carry the same preferences:

- Right Shift switches CN/EN. Left Shift stays a plain modifier; Ctrl+Space also switches (fcitx5 on
  Linux, the system input-source shortcut on macOS).
- Shift+Space does not toggle full/half width.
- `[ ] { }` produce corner brackets `「」『』`.

These sit in a schema-level patch rather than `default.custom.yaml` so they also override the
`default` preset and the schema's own bindings, and to avoid colliding with the `default.custom.yaml`
that ships in Squirrel's user directory.

## Hotkeys

The flypy schema brings its own bindings. Two worth remembering:

- Ctrl+J toggles simplified/traditional Chinese (简繁).
- Ctrl+. toggles Chinese/ASCII punctuation (中英标点).

The jidian schemas use the `default` preset's bindings; F4 (or Ctrl+`) opens Rime's schema menu.

## Applying changes

The custom files are store symlinks with an epoch mtime, so Rime does not notice when they change.
Remove `build/` and reload the Rime addon:

```sh
# Linux: reload the Rime addon (`fcitx5-remote -r` only reloads fcitx5's own config)
rm -rf ~/.local/share/fcitx5/rime/build
busctl --user call org.fcitx.Fcitx5 /controller org.fcitx.Fcitx.Controller1 ReloadAddonConfig s rime

# macOS: remove build/, then restart Squirrel
rm -rf ~/Library/Rime/build
```
