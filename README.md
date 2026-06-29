# tmux config

Personal tmux setup layered on top of [oh-my-tmux](https://github.com/gpakosz/.tmux).
Works on Linux and macOS.

## What's here

- `tmux.conf.local` — personal overrides (theme, plugins, key bindings).
- `install.sh` — clones oh-my-tmux, sets up symlinks, installs plugins. Idempotent.

The upstream oh-my-tmux files are **not** vendored here. The installer clones
them into `~/.tmux/` so updates can be pulled with `git -C ~/.tmux pull`.

## Install

```sh
git clone <this-repo-url> ~/.config/tmux
cd ~/.config/tmux
./install.sh
```

Then start a fresh tmux session — the theme and plugins load automatically.

## What the installer does

1. Clones `gpakosz/.tmux` into `~/.tmux/` (skipped if already present).
2. Symlinks `~/.tmux.conf` → `~/.tmux/.tmux.conf`.
3. Symlinks `~/.config/tmux/tmux.conf` → `~/.tmux/.tmux.conf` (XDG entry point oh-my-tmux expects).
4. Symlinks `~/.tmux.conf.local` → `~/.config/tmux/tmux.conf.local`.
5. Clones TPM into `~/.config/tmux/plugins/tpm/`.
6. Symlinks `~/.tmux/plugins` → `~/.config/tmux/plugins/`.
7. Clones each plugin directly into `~/.config/tmux/plugins/`.

Any pre-existing real files at those symlink paths are backed up with a
timestamped suffix — nothing is silently overwritten.

### Why step 6 (the plugins symlink) is necessary

oh-my-tmux's internal `_apply_plugins` function always derives
`TMUX_PLUGIN_MANAGER_PATH` from the location of `~/.tmux.conf`:

```sh
TMUX_PLUGIN_MANAGER_PATH="$(dirname "$TMUX_CONF")/plugins"
# → ~/.tmux/plugins
```

This value is computed in a subshell, so setting `set-environment` in
`tmux.conf.local` has no effect on it. Without the symlink, oh-my-tmux looks
for plugins in `~/.tmux/plugins` while they live in `~/.config/tmux/plugins`,
so TPM never sources them and the theme never loads.

### Why step 7 (direct git clones) instead of TPM headless install

`tpm/bin/install_plugins` requires a live tmux server to resolve
`TMUX_PLUGIN_MANAGER_PATH`. Run outside of a session it falls back to
`~/.tmux/plugins`, installs there, and the plugins end up in the wrong place.
Direct clones into the correct directory are simpler and reliable.

## Plugins

| Plugin | Purpose |
|---|---|
| [catppuccin/tmux](https://github.com/catppuccin/tmux) | Status bar theme |
| [christoomey/vim-tmux-navigator](https://github.com/christoomey/vim-tmux-navigator) | Seamless vim/tmux pane navigation |
| [sainnhe/tmux-fzf](https://github.com/sainnhe/tmux-fzf) | Fuzzy finder integration |

## Cross-platform notes

- **fish as default shell**: `tmux.conf.local` probes the common fish install
  paths (`/usr/bin/fish`, `/opt/homebrew/bin/fish`, `/usr/local/bin/fish`)
  and uses whichever exists. No fish, no problem — tmux falls back to `$SHELL`.
- **OS clipboard** (`tmux_conf_copy_to_os_clipboard=true`):
  - macOS: `brew install reattach-to-user-namespace`
  - Linux: install one of `xsel`, `xclip`, or `wl-copy`.

## Updating

```sh
# oh-my-tmux upstream
git -C ~/.tmux pull

# plugins (inside tmux: prefix + U, or manually)
~/.config/tmux/plugins/tpm/bin/update_plugins all
```

## Uninstall

```sh
rm ~/.tmux.conf ~/.tmux.conf.local
rm -rf ~/.tmux
rm -rf ~/.config/tmux
```
