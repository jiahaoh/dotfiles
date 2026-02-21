# dotfiles

Personal dotfiles managed with [GNU Stow](https://www.gnu.org/software/stow/). Works on macOS and Linux.

## Quick start (new machine)

```bash
git clone https://github.com/jiahaoh/dotfiles ~/dotfiles
cd ~/dotfiles
bash setup.sh
```

`setup.sh` will:
- Install packages (zsh, stow, tmux, git-lfs, eza, gh, starship)
- Install Miniforge3 (conda/mamba)
- Install Tmux Plugin Manager
- Back up any conflicting files to `~/.dotfiles_backup/`
- Symlink everything with `stow`

## Manual stow only

If dependencies are already installed:

```bash
cd ~/dotfiles
stow -t ~ .
```
