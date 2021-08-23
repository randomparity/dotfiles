#!/bin/bash

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

# Check for OS distro and version
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
echo -e "${INFO} Found $OS $VER [$ID]"


CURL_CHECK="Checking for curl"
# Check for important packages
PACKAGES=()
if ! command -v curl &> /dev/null; then
  echo -e "${CROSS} $CURL_CHECK"
  PACKAGES+=("curl")
else
  echo -e "${TICK} $CURL_CHECK"
fi

VIM_CHECK="Checking for vim"
if ! command -v vim &> /dev/null; then
  echo -e "${CROSS} $VIM_CHECK"
  PACKAGES+=("vim")
else
  echo -e "${TICK} $VIM_CHECK"
fi

CTAGS_CHECK="Checking for ctags"
if ! command -v ctags &> /dev/null; then
  echo -e "${CROSS} $CTAGS_CHECK"
  if [ $ID == "centos" ]; then
    PACKAGES+=("ctags")
  elif [ $ID == "rhel" ]; then
    PACKAGES+=("ctags")
  elif [ $ID == "fedora" ]; then
    PACKAGES+=("ctags")
  elif [ $ID == "ubuntu" ]; then
    PACKAGES+=("exuberant-ctags")
  fi
  # ToDo: What to do for other distros??
else
  echo -e "${TICK} $CTAGS_CHECK"
fi

TMUX_CHECK="Checking for tmux"
if ! command -v tmux &> /dev/null; then
  echo -e "${CROSS} $TMUX_CHECK"
  PACKAGES+=("tmux")
else
  echo -e "${TICK} $TMUX_CHECK"
fi

PYTHON_CHECK="Checking for python3"
if ! command -v python3 &> /dev/null; then
  echo -e "${CROSS} $PYTHON_CHECK"
  PACKAGES+=("python3")
else
  echo -e "${TICK} $PYTHON_CHECK"
fi

PIP_CHECK="Checking for pip3"
if ! command -v pip3 &> /dev/null; then
  echo -e "${CROSS} $PIP_CHECK"
  PACKAGES+=("python3-pip")
else
  echo -e "${TICK} $PIP_CHECK"
fi

# ToDo: Give option to install here
if (( ${#PACKAGES[@]} > 0 )); then
  if [ $ID == "centos" ]; then
    echo -e "${INFO} Run 'sudo yum install -y ${PACKAGES[@]}'"
    exit 1
  elif [ $ID == "rhel" ]; then
    echo -e "${INFO} Run 'sudo yum install -y ${PACKAGES[@]}'"
    exit 1
  elif [ $ID == "fedora" ]; then
    echo -e "${INFO} Run 'sudo yum install -y ${PACKAGES[@]}'"
    exit 1
  elif [ $ID == "ubuntu" ]; then
    echo -e "${INFO} Run 'sudo apt install -y ${PACKAGES[@]}'"
    exit 1
  fi
  echo -e "${CROSS} Setup incomplete, resolve dependencies and run setup again"
  exit 1
fi

# Known dependencies met, install powerline and symlink config files
# ToDo: Check for install error here
POWERLINE_INSTALL="Powerline install"
if python3 -m pip install --user powerline-status powerline-gitstatus &> /dev/null; then
  echo -e "${TICK} $POWERLINE_INSTALL"
else
  echo -e "${CROSS} $POWERLINE_INSTALL"
  echo "  Automated install failed, run 'python3 -m pip install --user powerline-status powerline-gitstatus' manually"
  echo "  then rerun $SCRIPT_NAME when finished to complete install"
  exit 1
fi

# Ensure powerline is installed for python version integrated within vim
# (RHEL 8.4 uses python3.6 for vim and python3.8 for /usr/bin/python3)
# (RHEL8 shows python version on gcc compilation line, Ubuntu shows it on link line)
# (Fedora 34 does not show python version in "vim --version" output, assume it matches system python)
SYS_PYTHON_VER=$(python3 --version 2>&1 | grep -Po '(?<=^Python )[0-9]*.[0-9]*(?=.[0-9A-Za-z-]*)')
VIM_PYTHON_VER=$(vim --version | grep -Po '^Compilation:.*[-/Ia-z]+python\K(3\.\d+)|Linking:.*[-a-z]python\K(3\.\d+)')
echo -e "${INFO} System python version: python$SYS_PYTHON_VER"
if [ -z $VIM_PYTHON_VER ]; then
  echo -e "${INFO} Vim python version   : Unknown"
else
  echo -e "${INFO} Vim python version   : python$VIM_PYTHON_VER"
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
[ ! -d "$HOME/.config" ] && mkdir -p "$HOME/.config"

# Backup any existing powerline configuration
if [ -f "$HOME/.config/powerline.backup" ]; then
  # echo -e "${CROSS} Found existing powerline backup file, skipping backup"
  :
elif [ -L "$HOME/.config/powerline.backup" ]; then
  # echo -e "${CROSS} Found existing powerline backup symlink, skipping backup"
  :
else
  [ -d "$HOME/.config/powerline" ] && mv "$HOME/.config/powerline" "$HOME/.config/powerline.backup" && echo -e "${CHECK} Backed up existing powerline config file"
fi

# Symlink powerline configuration from git source directory
if [ ! -L $HOME/.config/powerline ]; then
  if ln -sf "$SCRIPT_HOME/powerline" "$HOME/.config/powerline"; then
    echo -e "${TICK} Symlink $SCRIPT_HOME/powerline to $HOME/.config/powerline"
  else
    echo -e "${CROSS} Symlink $SCRIPT_HOME/powerline to $HOME/.config/powerline"
    # ToDo: Any error message here?
  fi
else
  echo -e "${INFO} Symlink $HOME/.config/powerline already exists, skipping"
fi

# Symlink all of our dotfiles to the home directory
for f in .vimrc .bashrc .bash_aliases .bash_profile .tmux.conf .gdbinit .dircolors; do
  # Backup any existing config files if present and not already backed up
  if [[ -e $HOME/$f && -f $HOME/$f.backup ]]; then
    # echo -e "${CROSS} Found existing $f backup file, skipping backup"
    :
  elif [[ -e $HOME/$f && -L $HOME/$f.backup ]]; then
    # echo -e "${CROSS} Found existing $f backup symlink, skipping backup"
    :
  elif [ -e $HOME/$f ]; then
    if mv $HOME/$f $HOME/$f.backup; then
      echo -e "${TICK} Backed up $HOME/$f to $HOME/$f.backup"
    else
      echo -e "${CROSS} Failed to backup $HOME/$f to $HOME/$f.backup, skipping"
    fi
  else
    echo -e "${CROSS} No existing file $f to backup, skipping"
  fi

  # Symlinking config file from git source directory
  if [ ! -L $HOME/$f ]; then
    if ln -sf $SCRIPT_HOME/$f $HOME/$f; then
      echo -e "${TICK} Symlink $SCRIPT_HOME/$f to $HOME/$f"
    else
      echo -e "${CROSS} Symlink $SCRIPT_HOME/$f to $HOME/$f"
    fi
  else
    echo -e "${INFO} Symlink $SCRIPT_HOME/$f already exists, skipping"
  fi
done

# Add git global configuration settings
# ToDo: Add error checking here
# ToDo: Better way to capture this info?

# Don't overwrite an existing configuration
GIT_CUR_NAME=$(git config --global user.name)
if [ -z "$GIT_CUR_NAME" ]; then
  if git config --global user.name "$GIT_NEW_NAME"; then	
    echo -e "${TICK} Set new git name $GIT_NEW_NAME)"
  else
    echo -e "${CROSS} Failed to set git name $GIT_NEW_NAME)"
  fi
else
  echo -e "${INFO} Git name already defined ($GIT_CUR_NAME), skipping"
fi

GIT_CUR_EMAIL=$(git config --global user.email)
if [ -z "$GIT_CUR_EMAIL" ]; then
  if git config --global user.email "$GIT_NEW_EMAIL"; then	
    echo -e "${TICK} Set new git email $GIT_NEW_EMAIL)"
  else
    echo -e "${CROSS} Failed to set git email $GIT_NEW_EMAIL)"
  fi
else
  echo -e "${INFO} Git email already defined ($GIT_CUR_EMAIL), skipping"
fi

GIT_CUR_NAME=$(git config --global user.name)
GIT_CUR_EMAIL=$(git config --global user.email)
echo -e "${TICK} Git global configuration ($GIT_CUR_NAME <$GIT_CUR_EMAIL>)"

# ToDo: Any error checking here?

# ToDo: Source the new configuration now?
echo -e "${TICK} Setup complete, logout/login to enable changes"

# ToDo: What if powerline installed system-wide??  How to handle?
