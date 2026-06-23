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

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$("$HOME/miniforge3/bin/conda" 'shell.bash' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "$HOME/miniforge3/etc/profile.d/conda.sh" ]; then
        . "$HOME/miniforge3/etc/profile.d/conda.sh"
    else
        export PATH="$HOME/miniforge3/bin:$PATH"
    fi
fi
unset __conda_setup

if [ -f "$HOME/miniforge3/etc/profile.d/mamba.sh" ]; then
    . "$HOME/miniforge3/etc/profile.d/mamba.sh"
fi
# <<< conda initialize <<<
