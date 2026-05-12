# tmux config

Personal tmux setup layered on top of [oh-my-tmux](https://github.com/gpakosz/.tmux).
Works on Linux and macOS.

## What's here

- `tmux.conf.local` — personal overrides (theme, plugins, key bindings).
- `install.sh` — clones oh-my-tmux, sets up symlinks, installs TPM. Idempotent.

The upstream oh-my-tmux files are **not** vendored here. The installer clones
them into `~/.tmux/` so updates can be pulled with `git -C ~/.tmux pull`.

## Install

```sh
git clone <this-repo-url> ~/.config/tmux
cd ~/.config/tmux
./install.sh
```

After install, launch tmux — plugins are installed automatically by the installer.

## What the installer does

1. Clones `gpakosz/.tmux` into `~/.tmux/` (skipped if already present).
2. Symlinks `~/.tmux.conf` → `~/.tmux/.tmux.conf`.
3. Symlinks `~/.config/tmux/tmux.conf` → `~/.tmux/.tmux.conf` (XDG entry point oh-my-tmux expects).
4. Symlinks `~/.tmux.conf.local` → `~/.config/tmux/tmux.conf.local`.
5. Clones TPM into `~/.config/tmux/plugins/tpm/`.
6. Runs `tpm/bin/install_plugins` to fetch all plugins declared in `tmux.conf.local`.

Any pre-existing real files at those symlink paths are backed up with a
timestamped suffix — nothing is silently overwritten.

## Cross-platform notes

- **fish as default shell**: `tmux.conf.local` probes the common fish install
  paths (`/usr/bin/fish`, `/opt/homebrew/bin/fish`, `/usr/local/bin/fish`)
  and uses whichever exists. No fish, no problem — tmux falls back to `$SHELL`.
- **OS clipboard** (`tmux_conf_copy_to_os_clipboard=true`):
  - macOS: `brew install reattach-to-user-namespace`
  - Linux: install one of `xsel`, `xclip`, or `wl-copy`.

## Updating oh-my-tmux upstream

```sh
git -C ~/.tmux pull
```

## Uninstall

```sh
rm ~/.tmux.conf ~/.tmux.conf.local
rm -rf ~/.tmux
```

If you cloned this repo into `~/.config/tmux/`, also remove the generated files
that `install.sh` created inside it:

```sh
rm ~/.config/tmux/tmux.conf
rm -rf ~/.config/tmux/plugins
# optionally remove the repo itself:
rm -rf ~/.config/tmux
```
