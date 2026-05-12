#!/usr/bin/env bash
# Idempotent installer for this tmux setup.
# Works on macOS and Linux. Safe to re-run.
#
# What it does:
#   1. Clones gpakosz/.tmux (oh-my-tmux) into ~/.tmux if missing.
#   2. Symlinks ~/.tmux.conf -> ~/.tmux/.tmux.conf (the upstream main config).
#   3. Symlinks <this repo>/tmux.conf -> ~/.tmux/.tmux.conf (XDG entry point).
#   4. Symlinks ~/.tmux.conf.local -> <this repo>/tmux.conf.local.
#   5. Installs TPM (tmux plugin manager) into <this repo>/plugins/tpm if missing.
#   6. Runs TPM headless install to fetch all plugins declared in tmux.conf.local.
#   7. Backs up any pre-existing real files (not symlinks) before replacing.

set -euo pipefail

# Resolve the directory containing this script (follows symlinks; bash 3.2 safe).
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do
  DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
REPO_DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"

OHMYTMUX_DIR="${HOME}/.tmux"
TPM_DIR="${REPO_DIR}/plugins/tpm"
TS="$(date +%Y%m%d-%H%M%S)"

info()  { printf '\033[1;34m[*]\033[0m %s\n' "$*"; }
ok()    { printf '\033[1;32m[✓]\033[0m %s\n' "$*"; }
warn()  { printf '\033[1;33m[!]\033[0m %s\n' "$*"; }
die()   { printf '\033[1;31m[x]\033[0m %s\n' "$*" >&2; exit 1; }

command -v git   >/dev/null 2>&1 || die "git is required but not installed."
command -v tmux  >/dev/null 2>&1 || warn "tmux is not on PATH — install it (brew install tmux / apt install tmux)."

# 1. Clone oh-my-tmux if needed.
if [ ! -d "$OHMYTMUX_DIR/.git" ]; then
  if [ -e "$OHMYTMUX_DIR" ]; then
    warn "$OHMYTMUX_DIR exists but is not a git repo — backing it up."
    mv "$OHMYTMUX_DIR" "${OHMYTMUX_DIR}.bak.${TS}"
  fi
  info "Cloning gpakosz/.tmux into $OHMYTMUX_DIR"
  git clone --depth 1 https://github.com/gpakosz/.tmux.git "$OHMYTMUX_DIR"
  ok "Cloned oh-my-tmux."
else
  ok "oh-my-tmux already present at $OHMYTMUX_DIR"
fi

# Helper: symlink $1 -> $2, backing up an existing real file/dir.
link() {
  local target="$1" linkpath="$2"
  if [ -L "$linkpath" ]; then
    if [ "$(readlink "$linkpath")" = "$target" ]; then
      ok "$linkpath -> $target (already correct)"
      return
    fi
    info "Replacing symlink $linkpath (was -> $(readlink "$linkpath"))"
    rm "$linkpath"
  elif [ -e "$linkpath" ]; then
    warn "Backing up $linkpath -> ${linkpath}.bak.${TS}"
    mv "$linkpath" "${linkpath}.bak.${TS}"
  fi
  ln -s "$target" "$linkpath"
  ok "$linkpath -> $target"
}

# 2, 3 & 4. Symlinks.
link "$OHMYTMUX_DIR/.tmux.conf"   "$HOME/.tmux.conf"
link "$OHMYTMUX_DIR/.tmux.conf"   "$REPO_DIR/tmux.conf"
link "$REPO_DIR/tmux.conf.local"  "$HOME/.tmux.conf.local"

# 5. TPM.
if [ ! -d "$TPM_DIR/.git" ]; then
  info "Installing TPM into $TPM_DIR"
  mkdir -p "$(dirname "$TPM_DIR")"
  git clone --depth 1 https://github.com/tmux-plugins/tpm "$TPM_DIR"
  ok "TPM installed."
else
  ok "TPM already present."
fi

# 6. Install plugins headlessly via TPM.
info "Installing tmux plugins via TPM..."
if "$TPM_DIR/bin/install_plugins" 2>&1 | sed 's/^/    /'; then
  ok "Plugins installed."
else
  warn "One or more plugins failed to install — check output above."
fi

# Friendly closing notes.
echo
ok "Install complete."
echo
echo "Next steps:"
echo "  • Start (or reload) tmux:   tmux new-session  /  tmux source ~/.tmux.conf"
echo "  • To reload config:         <prefix> + r"
echo
case "$(uname -s)" in
  Darwin)
    echo "macOS notes:"
    echo "  • For OS clipboard integration, install: brew install reattach-to-user-namespace"
    echo "  • If you use fish, install it: brew install fish"
    ;;
  Linux)
    echo "Linux notes:"
    echo "  • For OS clipboard integration, install one of: xsel, xclip, or wl-copy"
    echo "  • If you use fish, install it: sudo apt install fish  (or your distro's pkg mgr)"
    ;;
esac
