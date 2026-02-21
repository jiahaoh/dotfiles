
# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/Users/jiahao/miniforge3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/Users/jiahao/miniforge3/etc/profile.d/conda.sh" ]; then
        . "/Users/jiahao/miniforge3/etc/profile.d/conda.sh"
    else
        export PATH="/Users/jiahao/miniforge3/bin:$PATH"
    fi
fi
unset __conda_setup

if [ -f "/Users/jiahao/miniforge3/etc/profile.d/mamba.sh" ]; then
    . "/Users/jiahao/miniforge3/etc/profile.d/mamba.sh"
fi
# <<< conda initialize <<<

eval "$(starship init zsh)"
source /Users/jiahao/.aliases

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/jiahao/google-cloud-sdk/path.zsh.inc' ]; then . '/Users/jiahao/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/Users/jiahao/google-cloud-sdk/completion.zsh.inc' ]; then . '/Users/jiahao/google-cloud-sdk/completion.zsh.inc'; fi

# Add ~/.local/ to PATH
export PATH=$HOME/.local/bin:$PATH
export PATH="/opt/homebrew/opt/ruby/bin:$PATH"
