#!/usr/bin/env bash
# Auto-launch zsh on systems where bash is the default shell.
# On macOS zsh is already default, so this is a no-op.
if [ -z "$ZSH_VERSION" ] && command -v zsh >/dev/null 2>&1; then
    export SHELL="$(command -v zsh)"
    exec "$SHELL" -l
fi

# Bash fallback (only reached if zsh is not available)
[ -f "$HOME/.bashrc" ] && source "$HOME/.bashrc"
[ -f "$HOME/.aliases" ] && source "$HOME/.aliases"
