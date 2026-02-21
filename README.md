# dotfiles

Personal dotfiles managed with [GNU Stow](https://www.gnu.org/software/stow/).

## Install

```bash
git clone https://github.com/jiahaoh/dotfiles ~/Desktop/GitHub/jiahaoh/dotfiles
cd ~/Desktop/GitHub/jiahaoh/dotfiles
stow -t ~ .
```

## On a new machine

```bash
git clone https://github.com/jiahaoh/dotfiles ~/dotfiles
cd ~/dotfiles
stow -t ~ .    # if stow available
```
