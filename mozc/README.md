# Mozc keymap customization

Mozc stores all settings (including the custom keymap table) in a single
binary file (`~/.config/mozc/config1.db`) that also mixes in typing
history / personalization data, so that file isn't symlinked from this
repo. Instead, [`keymap.ubuntu24.ibus-mozc.txt`](keymap.ubuntu24.ibus-mozc.txt)
is a plain-text export of just the custom keymap table (via Mozc's
keymap editor "エクスポート" button), which can be re-imported on a new
machine.

Base keymap style: **MS-IME** (キー設定の選択 → Microsoft IME).

Exported from Ubuntu 24.04's `ibus-mozc`/`mozc-data`/`mozc-utils-gui`
`2.28.4715.102+dfsg-2.2build7`. Mozc renamed several keymap command
names across versions (e.g. `InputModeHiragana` vs.
`CompositionModeHiragana`), so an import on a differently-versioned
Mozc may not apply cleanly — hence the filename records the source
environment. If that happens, re-derive the 3 changes from the
"Changes from the MS-IME default" table below by hand instead.

## Why

Left/Right Alt are remapped via xremap ([`xremap/config.yml`](../xremap/config.yml))
so that tapping Left Alt sends `Muhenkan` and tapping Right Alt sends
`Henkan`, to emulate macOS-style Eisu/Kana IME switching:
`Henkan` activates IME, `Muhenkan` deactivates it.

The MS-IME default keymap doesn't fit that model (`Henkan` defaults to
`Reconvert` in `DirectInput`, and pressing `Henkan` again while already
in Japanese input mode triggers Mozc's "reconversion" feature, which
pulls in the app's selected/clipboard-adjacent text and converts it —
very surprising when you just meant "already in Japanese mode, do
nothing").

## Changes from the MS-IME default

| Mode | Key | Default command | Custom command |
|------|-----|------------------|-----------------|
| `DirectInput` | `Henkan` | `Reconvert` | `IMEOn` |
| `Precomposition` | `Muhenkan` | `SwitchKanaType` | `IMEOff` |
| `Precomposition` | `Henkan` | `Reconvert` | *(row removed — no command)* |

## How to reproduce on a new machine

1. Open the Mozc config dialog: `mozc_tool --mode=config_dialog`
2. Go to the "キー設定" (Keymap) tab, set "キー設定の選択" to `カスタム`
   (Custom), then click "編集" (Edit) to open the keymap table editor.
3. Click "インポート" (Import) and select this repo's
   `mozc/keymap.ubuntu24.ibus-mozc.txt`.
4. Save / close the dialogs. No restart is required.

There's no known CLI to script the import, so it has to be done once by
hand per machine. If you make further keymap changes, re-export
("エクスポート") over `mozc/keymap.ubuntu24.ibus-mozc.txt` to keep this
in sync (rename the file if the source environment changes).
