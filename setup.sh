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

if [ $ID == "centos" ]; then
  :
elif [ $ID == "rhel" ]; then
  :
elif [ $ID == "fedora" ]; then
  :
elif [ $ID == "ubuntu" ]; then
  :
elif [ $ID == "debian" ]; then
  :
else
  echo -e "${CROSS} Validating OS distro failed, $SCRIPT_NAME must be modified"
  exit 1
fi


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
  if [ $ID == "centos" ]; then
    PACKAGES+=("vim")
  elif [ $ID == "rhel" ]; then
    PACKAGES+=("vim")
  elif [ $ID == "fedora" ]; then
    PACKAGES+=("vim")
  elif [ $ID == "ubuntu" ]; then
    PACKAGES+=("vim")
  elif [ $ID == "debian" ]; then
    PACKAGES+=("vim-nox")
  fi
  # ToDo: What to do for other distros??
else
  echo -e "${TICK} $VIM_CHECK"
  VIM_PYTHON_CHECK="$VIM_CHECK with python3 support"
  if ! vim --version | grep \+python3 &> /dev/null; then
    echo -e "${CROSS} $VIM_PYTHON_CHECK"
    if [ $ID == "centos" ]; then
      PACKAGES+=("vim")
    elif [ $ID == "rhel" ]; then
      PACKAGES+=("vim")
    elif [ $ID == "fedora" ]; then
      PACKAGES+=("vim")
    elif [ $ID == "ubuntu" ]; then
      PACKAGES+=("vim")
    elif [ $ID == "debian" ]; then
      PACKAGES+=("vim-nox")
    fi
    # ToDo: What to do for other distros??
  else
    echo -e "${TICK} $VIM_PYTHON_CHECK"
  fi
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
  elif [ $ID == "debian" ]; then
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
  elif [ $ID == "debian" ]; then
    echo -e "${INFO} Run 'sudo apt install -y ${PACKAGES[@]}'"
    exit 1
  fi
  echo -e "${CROSS} Setup incomplete, resolve dependencies and run setup again"
  exit 1
fi

# Known dependencies met, install powerline and symlink config files
# ToDo: Check for install error here
POWERLINE_INSTALL="Installing powerline"
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
