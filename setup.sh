#!/bin/bash

# Store where the script was called from so we can reference it later
SCRIPT_HOME="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# ToDo: Install powerline locally

# Symlink powerline into the .config directoy
[ ! -d "$HOME/.config" ] && mkdir -p "$HOME/.config"
[ -d "$HOME/.config/powerline" ] && mv "$HOME/.config/powerline" "$HOME/.config/powerline.backup"
ln -sf "$SCRIPT_HOME/powerline" "$HOME/.config/powerline"

# Symlink all of our dotfiles to the home directory
for f in .vimrc .bashrc .bash_aliases .bash_profile .bash_darwin .tmux.conf .gdbinit .gitconfig .dircolors;
do
  [ -e $HOME/$f ] && mv $HOME/$f $HOME/$f.backup
  ln -sf $SCRIPT_HOME/$f $HOME/$f
done

