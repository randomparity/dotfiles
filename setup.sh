#!/bin/bash

# Store where the script was called from so we can reference it later
SCRIPT_HOME="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Make sure python3/pip are installed
if ! command -v python3 &> /dev/null; then
  echo "Can't find python3, exiting..."
  exit 1
fi

if ! command -v pip3 &> /dev/null; then
  echo "Can't find pip3, exiting..."
  exit 1
fi

# Unconditionally install powerline locally
python3 -m pip install --user powerline-status powerline-gitstatus

# Symlink powerline into the .config directoy
[ ! -d "$HOME/.config" ] && mkdir -p "$HOME/.config"
[ -d "$HOME/.config/powerline" ] && mv "$HOME/.config/powerline" "$HOME/.config/powerline.backup"
ln -sf "$SCRIPT_HOME/powerline" "$HOME/.config/powerline"

# Symlink all of our dotfiles to the home directory
for f in .vimrc .bashrc .bash_aliases .bash_profile .tmux.conf .gdbinit .dircolors;
do
  [ -e $HOME/$f ] && mv $HOME/$f $HOME/$f.backup
  ln -sf $SCRIPT_HOME/$f $HOME/$f
done

