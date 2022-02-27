#!/bin/bash

# set -x

###########################################################
# Customizations (Begin)
###########################################################
GIT_NEW_NAME="David Christensen"
GIT_NEW_EMAIL="randomparity@gmail.com"
###########################################################
# Customizations (End)
###########################################################

# ToDo: How to find location of dotfile git repository?
# Store where the script was called from so we can reference it later
SCRIPT_NAME="$0"
SCRIPT_HOME="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source COLOR_TABLE

OS="unknown"
VER="unknown"
ID="unknown"

##############################################################################
# Check for OS distro and version
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
  if [ -f /etc/os-release ]; then
    # freedesktop.org and systemd
    . /etc/os-release
    OS=$NAME
    VER=$VERSION
    ID=$ID
  elif type lsb_release >/dev/null 2>&1; then
    # linuxbase.org
    OS=$(lsb_release -si)
    VER=$(lsb_release -sr)
  elif [ -f /etc/lsb-release ]; then
    # For some versions of Debian/Ubuntu without lsb_release command
    . /etc/lsb-release
    OS=$DISTRIB_ID
    VER=$DISTRIB_RELEASE
  elif [ -f /etc/debian_version ]; then
    # Older Debian/Ubuntu/etc.
    OS=Debian
    VER=$(cat /etc/debian_version)
  elif [ -f /etc/SuSe-release ]; then
    # Older SuSE/etc.
    echo -e "${CROSS} Can't parse /etc/SuSe-release"
    exit 1
  elif [ -f /etc/redhat-release ]; then
    echo -e "${CROSS} Can't parse /etc/redhat-release"
    exit 1
  else
    # Fall back to uname, e.g. "Linux <version>", also works for BSD, etc.
    OS=$(uname -s)
    VER=$(uname -r)
  fi

  case $ID in
    ubuntu | debian) ;;
    centos | rhel | fedora) ;;
    *) echo -e "${CROSS} Validating Linux distro failed, $SCRIPT_NAME must be modified" && exit 1;;
  esac
elif [[ "$OSTYPE" == "darwin"* ]]; then
    # Mac OSX
    OS=MacOSX
fi
echo -e "${INFO} Found $OS $VER [$ID]"

[[ ! -f .setup_completed ]] && echo -e "${CROSS} Did you run setup.sh?" && exit 1
echo -e "${TICK} Checking for pre-requisites"

##############################################################################
# Install pyenv & local python version
PYENV_CHECK="Installing pyenv"
PYENV_VER="3.9.10"
if [[ ! -f $HOME/.pyenv/bin/pyenv ]]; then
  curl https://pyenv.run | bash
fi

# Verify the install worked
if [[ ! -f $HOME/.pyenv/bin/pyenv ]]; then
  echo -e "${CROSS} $PYENV_CHECK"
  exit 1
else
  echo -e "${TICK} $PYENV_CHECK"
fi

# Setup the pyenv environment for use in the rest of this script
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init --path)"
eval "$(pyenv virtualenv-init -)"

# Configure a local python install
echo -e "${TICK} Installing & selecting python $PYENV_VER"
pyenv install -s $PYENV_VER
pyenv global $PYENV_VER

##############################################################################
# Fetch and install a local copy of pip
PIP_FETCH="Fetching pip installer"
if wget https://bootstrap.pypa.io/get-pip.py > /dev/null 2>&1; then
  echo -e "${TICK} $PIP_FETCH"
else
  echo -e "${CROSS} $PIP_FETCH"
  exit 1
fi

PIP_INSTALL="Installing pip"
if python3 get-pip.py > /dev/null 2>&1; then
  rm get-pip.py
  echo -e "${TICK} $PIP_INSTALL"
else
  echo -e "${CROSS} $PIP_INSTALL"
  exit 1
fi

##############################################################################
# Fetch and install powerline
POWERLINE_INSTALL="Installing powerline"
if python3 -m pip install --user powerline-status powerline-gitstatus &> /dev/null; then
  echo -e "${TICK} $POWERLINE_INSTALL"
else
  # ToDo: Is this accurate?
  echo -e "${CROSS} $POWERLINE_INSTALL"
  echo "  Automated install failed, run 'python3 -m pip install --user powerline-status powerline-gitstatus' manually"
  echo "  then rerun $SCRIPT_NAME when finished to complete install"
  exit 1
fi

##############################################################################
# Ensure powerline is installed for python version integrated within vim
# (RHEL 8.4 uses python3.6 for vim and python3.8 for /usr/bin/python3)
# (RHEL8 shows python version on gcc compilation line, Ubuntu shows it on link line)
# (Fedora 34 does not show python version in "vim --version" output, assume it matches system python)
SYS_PYTHON_VER=$(python3 --version 2>&1 | grep -Po '(?<=^Python )[0-9]*.[0-9]*(?=.[0-9A-Za-z-]*)')
VIM_PYTHON_VER=$(vim --version | grep -Po '^Compilation:.*[-/Ia-z]+python\K(3\.\d+)|Linking:.*[-a-z]python\K(3\.\d+)')
echo -e "${INFO} Found system python version: python$SYS_PYTHON_VER"
if [ -z $VIM_PYTHON_VER ]; then
  echo -e "${INFO} Found vim python version   : Unknown"
else
  echo -e "${INFO} Found vim python version   : python$VIM_PYTHON_VER"
fi

if [[ ! -z $VIM_PYTHON_VER && $SYS_PYTHON_VER != $VIM_PYTHON_VER ]]; then
  if python$VIM_PYTHON_VER -m pip install --user powerline-status powerline-gitstatus &> /dev/null; then
    echo -e "${TICK} $POWERLINE_INSTALL for vim"
  else
    echo -e "${CROSS} $POWERLINE_INSTALL for vim"
    echo "  Automated install failed, run 'python$VIM_PYTHON_VER -m pip install --user powerline-status powerline-gitstatus' manually"
    echo "  then rerun $SCRIPT_NAME when finished to complete install"
    exit 1
  fi
fi

# Ensure we have a ~/.config directory
[ ! -d "$HOME/.config" ] && mkdir -p "$HOME/.config" && echo -e "${TICK} Creating $HOME/.config"

# Backup any existing powerline configuration
POWERLINE_BACKUP_INSTALL="Backing up existing powerline config file"
if [ -f "$HOME/.config/powerline.backup" ]; then
  # echo -e "${CROSS} $POWERLINE_BACKUP_INSTALL skipped, found existing backup"
  :
elif [ -L "$HOME/.config/powerline.backup" ]; then
  # echo -e "${CROSS} $POWERLINE_BACKUP_INSTALL skipped, found existing symlink"
  :
else
  [ -d "$HOME/.config/powerline" ] && mv "$HOME/.config/powerline" "$HOME/.config/powerline.backup" && echo -e "${TICK} $POWERLINE_BACKUP_INSTALL"
fi

# Symlink powerline configuration from git source directory
POWERLINE_SYMLINK_INSTALL="Creating symlink from $SCRIPT_HOME/powerline to $HOME/.config/powerline"
if [ ! -L $HOME/.config/powerline ]; then
  if ln -sf "$SCRIPT_HOME/powerline" "$HOME/.config/powerline"; then
    echo -e "${TICK} $POWERLINE_SYMLINK_INSTALL"
  else
    echo -e "${CROSS} $POWERLINE_SYMLINK_INSTALL"
    # ToDo: Any error actions here?
  fi
else
  echo -e "${INFO} $POWERLINE_SYMLINK_INSTALL skipped, found existing symlink"
fi

# Symlink all of our dotfiles to the home directory
for f in .vimrc .bashrc .bash_aliases .bash_profile .tmux.conf .gdbinit .dircolors; do
  DOTFILE_BACKUP_INSTALL="Backing up $HOME/$f to $HOME/$f.backup"
  DOTFILE_SYMLINK_INSTALL="Creating symlink from $HOME/$f to $HOME/$f.backup"
  # Backup any existing config files if present and not already backed up
  if [[ -e $HOME/$f && -f $HOME/$f.backup ]]; then
    # echo -e "${CROSS} $DOTFILE_BACKUP_INSTALL skipped, found existing backup"
    :
  elif [[ -e $HOME/$f && -L $HOME/$f.backup ]]; then
    # echo -e "${CROSS} $DOTFILE_BACKUP_INSTALL skipped, found existing symlink"
    :
  elif [ -e $HOME/$f ]; then
    if mv $HOME/$f $HOME/$f.backup; then
      echo -e "${TICK} $DOTFILE_BACKUP_INSTALL"
    else
      echo -e "${CROSS} $DOTFILE_BACKUP_INSTALL failed"
      # ToDo: Any error actions here?
    fi
  else
    # echo -e "${INFO} $DOTFILE_BACKUP_INSTALL skipped, no existing file to backup"
    :
  fi

  # Symlinking config file from git source directory
  if [ ! -L $HOME/$f ]; then
    if ln -sf $SCRIPT_HOME/$f $HOME/$f; then
      echo -e "${TICK} $DOTFILE_SYMLINK_INSTALL"
    else
      echo -e "${CROSS} $DOTFILE_SYMLINK_INSTALL failed"
    fi
  else
    echo -e "${INFO} $DOTFILE_SYMLINK_INSTALL skipped, found existing symlink"
  fi
done

# Add git global configuration settings
# ToDo: Add error checking here
# ToDo: Better way to capture this info?

# Don't overwrite an existing configuration
GIT_CUR_NAME=$(git config --global user.name)
GIT_NAME_INSTALL="Setting git name ($GIT_NEW_NAME)"
if [ -z "$GIT_CUR_NAME" ]; then
  if git config --global user.name "$GIT_NEW_NAME"; then	
    echo -e "${TICK} $GIT_NAME_INSTALL"
  else
    echo -e "${CROSS} $GIT_NAME_INSTALL failed"
  fi
else
  echo -e "${INFO} $GIT_NAME_INSTALL skipped, $GIT_CUR_NAME already defined"
fi

GIT_CUR_EMAIL=$(git config --global user.email)
GIT_EMAIL_INSTALL="Setting git email ($GIT_NEW_EMAIL)"
if [ -z "$GIT_CUR_EMAIL" ]; then
  if git config --global user.email "$GIT_NEW_EMAIL"; then	
    echo -e "${TICK} $GIT_EMAIL_INSTALL"
  else
    echo -e "${CROSS} $GIT_EMAIL_INSTALL failed"
  fi
else
  echo -e "${INFO} $GIT_EMAIL_INSTALL skipped, $GIT_CUR_EMAIL already defined"
fi

GIT_CUR_NAME=$(git config --global user.name)
GIT_CUR_EMAIL=$(git config --global user.email)
echo -e "${TICK} Git global configuration ($GIT_CUR_NAME <$GIT_CUR_EMAIL>)"

# Configure git "fixline" alias for DPDK work
GIT_FIXLINE_INSTALL="Setting git fixline alias"
if git config alias.fixline "log -1 --abbrev=12 --format='Fixes: %h (\"%s\")%nCc: %ae'"; then
  echo -e "${TICK} $GIT_FIXLINE_INSTALL"
else
  echo -e "${CROSS} $GIT_FIXLINE_INSTALL failed"
fi

GIT_PULL_FF_INSTALL="Setting git pull mode to fast-forward"
if git config pull.ff only; then
  echo -e "${TICK} $GIT_PULL_FF_INSTALL"
else
  echo -e "${CROSS} $GIT_PULL_FF_INSTALL failed"
fi

GIT_DEF_BRANCH_NAME="Setting git default branch name to main"
if git config --global init.defaultBranch main; then
  echo -e "${TICK} $GIT_DEF_BRANCH_NAME"
else
  echo -e "${CROSS} $GIT_DEF_BRANCH_NAME failed"
fi

# ToDo: Any error checking here?

# ToDo: Source the new configuration now?
echo -e "${TICK} Setup complete, logout/login to enable changes"

# ToDo: What if powerline installed system-wide??  How to handle?
