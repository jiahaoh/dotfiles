# dotfiles

Personal dotfiles managed with [GNU Stow](https://www.gnu.org/software/stow/). Works on macOS and Linux.

## Quick start (new machine)

```bash
git clone https://github.com/jiahaoh/dotfiles ~/dotfiles
cd ~/dotfiles
bash setup.sh primary
```

`setup.sh primary` is the recommended starting point for a company-issued laptop.
It installs and links only the portable baseline:

- Shell and Git tools: zsh, stow, git-lfs, eza, gh, starship
- Linux support packages: git, curl, gpg
- Dotfiles: `.zshrc`, `.zprofile`, `.bash_profile`, `.aliases`, `.gitconfig`,
  `.config/git/ignore`, `.config/gh/config.yml`, `.config/starship.toml`

Primary setup intentionally skips:

- `.ssh/config`
- `.claude/*`
- tmux config and plugins
- Miniforge3 / conda / mamba

Full setup is still available:

```bash
bash setup.sh full
```

`setup.sh full` will:
- Install primary packages plus tmux, tmuxinator, jq, and zsh plugins
- Install Miniforge3
- Install Tmux Plugin Manager
- Link all tracked dotfiles
- Back up any conflicting files to `~/.dotfiles_backup/`
- Symlink everything with `stow`

Before running either profile on a machine with existing shell, Git, SSH, or
Claude configuration, preview stow changes:

```bash
stow -nv -t ~ .
```

## Manual stow only

If dependencies are already installed:

```bash
cd ~/dotfiles
stow -t ~ .
```
