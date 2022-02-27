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

NOW=$(date +"%Y-%m-%d-%T")
LOG_DIR=$SCRIPT_HOME/logs/$NOW
LOG_FILE=$LOG_DIR/config.log
BACKUP_DIR=$SCRIPT_HOME/backups/$NOW
mkdir -p $LOG_DIR
mkdir -p $BACKUP_DIR

# Function to echo commands to log file as they are executed
exe() {
  params=("$@")
  # Print the command and parameters to the log file
  printf "%s\t%q" "$(date)" "${params[0]}" >> "$LOG_FILE"
  printf " %q" "${params[@]:1}" >> "$LOG_FILE"
  printf "\n" >> "$LOG_FILE"
  # Execute the command and log the output
  "${params[@]}" >> $LOG_FILE
}

# Function to write status to the console and a log file (with ANSI stripped)
log() {
  echo -e "$@" | tee -a $LOG_FILE
  # echo -e "$@" | sed 's/\x1b\[[0-9;]*m//g' | tee -a $LOG_FILE
  # https://superuser.com/questions/380772/removing-ansi-color-codes-from-text-stream
  # perl -pe ' s/\e\[[\x30-\x3f]*[\x20-\x2f]*[\x40-\x7e]//g; s/\e[PX^_].*?\e\\//g; s/\e\][^\a]*(?:\a|\e\\)//g; s/\e[\[\]A-Z\\^_@]//g;'
}

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
    log "${CROSS} Can't parse /etc/SuSe-release"
    exit 1
  elif [ -f /etc/redhat-release ]; then
    log "${CROSS} Can't parse /etc/redhat-release"
    exit 1
  else
    # Fall back to uname, e.g. "Linux <version>", also works for BSD, etc.
    OS=$(uname -s)
    VER=$(uname -r)
  fi

  case $ID in
    ubuntu | debian) ;;
    centos | rhel | fedora) ;;
    *) log -e "${CROSS} Validating Linux distro failed, $SCRIPT_NAME must be modified" && exit 1;;
  esac
elif [[ "$OSTYPE" == "darwin"* ]]; then
    # Mac OSX
    OS=MacOSX
fi
log "${INFO} Found $OS $VER [$ID]"

[[ ! -f .setup_completed ]] && log "${CROSS} Did you run setup.sh?" && exit 1
log "${TICK} Checking for pre-requisites"

##############################################################################
# This section is tricky.  In order to use powerline with VIM we need to 
# install a version of powerline that matches the python version support built
# into vim.  On the other hand, we want a more current version of python for
# development which likely requires a different version of powerline for the
# bash shell.  
##############################################################################

##############################################################################
# Install pyenv & a local python version
PYENV_CHECK="Installing pyenv"
PYENV_VER="3.9.10"
if [[ ! -f $HOME/.pyenv/bin/pyenv ]]; then
  curl https://pyenv.run | bash
fi

# Verify that the install worked
if [[ ! -f $HOME/.pyenv/bin/pyenv ]]; then
  log "${CROSS} $PYENV_CHECK"
  exit 1
else
  log "${TICK} $PYENV_CHECK"
fi

# Setup the pyenv environment for use in the rest of this script
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init --path)"
eval "$(pyenv virtualenv-init -)"

# Ensure the system python is selected
pyenv global system

##############################################################################
# Fetch and install a powerline instance that matches VIM's python version
#
# RHEL 8.4     - VIM uses python3.6 and system uses python3.8
# Ubuntu 18.04 - System uses python3.6
# Ubuntu 20.04 - 
#
# - RHEL8 shows python version on gcc compilation line
# - Ubuntu shows python version on link line
# - Fedora 34 does not show python version in "vim --version" output, assume
#   it matches system python
POWERLINE_INSTALL="Installing powerline"
SYS_PYTHON_VER=$(python3 --version 2>&1 | grep -Po '(?<=^Python )[0-9]*.[0-9]*(?=.[0-9A-Za-z-]*)')
VIM_PYTHON_VER=$(vim --version | grep -Po '^Compilation:.*[-/Ia-z]+python\K(3\.\d+)|Linking:.*[-a-z]python\K(3\.\d+)')
log "${INFO} Found system python version: python$SYS_PYTHON_VER"
if [ -z $VIM_PYTHON_VER ]; then
  log "${INFO} Found vim python version   : Unknown"
else
  log "${INFO} Found vim python version   : python$VIM_PYTHON_VER"
fi

if [[ ! -z $VIM_PYTHON_VER ]]; then
  if python$VIM_PYTHON_VER -m pip install --user powerline-status powerline-gitstatus &> /dev/null; then
    log "${TICK} $POWERLINE_INSTALL for vim"
  else
    log "${CROSS} $POWERLINE_INSTALL for vim"
    echo "  Automated install failed, run 'python$VIM_PYTHON_VER -m pip install --user powerline-status powerline-gitstatus' manually"
    echo "  then rerun $SCRIPT_NAME when finished to complete install"
    exit 1
  fi
fi

if [[ ! -z $SYS_PYTHON_VER ]]; then
  if python3 -m pip install --user powerline-status powerline-gitstatus &> /dev/null; then
    log "${TICK} $POWERLINE_INSTALL for system"
  else
    log "${CROSS} $POWERLINE_INSTALL for system"
    echo "  Automated install failed, run 'python$SYS_PYTHON_VER -m pip install --user powerline-status powerline-gitstatus' manually"
    echo "  then rerun $SCRIPT_NAME when finished to complete install"
    exit 1
  fi
fi

##############################################################################
# Install a local python version and set it as default
log "${TICK} Installing & selecting local python $PYENV_VER"
pyenv install -s $PYENV_VER
pyenv global $PYENV_VER

##############################################################################
# Fetch and install a copy of pip for our local python version
PIP_FETCH="Fetching local pip installer"
if wget https://bootstrap.pypa.io/get-pip.py >> $LOG_FILE 2>&1; then
  # https://bootstrap.pypa.io/pip/3.6/get-pip.py
  log "${TICK} $PIP_FETCH" | sed 's/\x1b\[[0-9;]*m//g' | tee -a $LOG_FILE
else
  log "${CROSS} $PIP_FETCH" | sed 's/\x1b\[[0-9;]*m//g' | tee -a $LOG_FILE
  exit 1
fi

PIP_INSTALL="Installing local pip"
if python3 get-pip.py > $LOG_FILE 2>&1; then
  rm get-pip.py
  log "${TICK} $PIP_INSTALL" | sed 's/\x1b\[[0-9;]*m//g' | tee -a $LOG_FILE
else
  log "${CROSS} $PIP_INSTALL" | sed 's/\x1b\[[0-9;]*m//g' | tee -a $LOG_FILE
  exit 1
fi

##############################################################################
# Fetch and install powerline for our local python version
if python3 -m pip install --user powerline-status powerline-gitstatus &> /dev/null; then
  log "${TICK} $POWERLINE_INSTALL"
else
  # ToDo: Is this accurate?
  log "${CROSS} $POWERLINE_INSTALL"
  echo "  Automated install failed, run 'python3 -m pip install --user powerline-status powerline-gitstatus' manually"
  echo "  then rerun $SCRIPT_NAME when finished to complete install"
  exit 1
fi

##############################################################################
# Ensure we have a ~/.config directory
[ ! -d "$HOME/.config" ] && mkdir -p "$HOME/.config" && log "${TICK} Creating $HOME/.config"

##############################################################################
# Backup any existing powerline configuration
POWERLINE_BACKUP_INSTALL="Saving existing powerline config file"
if [ -L "$HOME/.config/powerline" ]; then
  log "${CROSS} $POWERLINE_BACKUP_INSTALL skipped, found existing symlink"
else
  [ -d "$HOME/.config/powerline" ] && mv "$HOME/.config/powerline" "$BACKUP_DIR/powerline" && log "${TICK} $POWERLINE_BACKUP_INSTALL"
fi

##############################################################################
# Symlink powerline configuration from git source directory
POWERLINE_SYMLINK_INSTALL="Symlinking $SCRIPT_HOME/powerline to $HOME/.config/powerline"
if [ -L "$HOME/.config/powerline" ]; then
  log "${INFO} $POWERLINE_SYMLINK_INSTALL skipped, found existing symlink"
else
  if ln -sf "$SCRIPT_HOME/powerline" "$HOME/.config/powerline"; then
    log "${TICK} $POWERLINE_SYMLINK_INSTALL"
  else
    log "${CROSS} $POWERLINE_SYMLINK_INSTALL"
  fi
fi

##############################################################################
# Symlink new dotfiles to the home directory
for f in .vimrc .bashrc .bash_aliases .bash_profile .tmux.conf .gdbinit .dircolors; do
  DOTFILE_BACKUP_INSTALL="Backing up $HOME/$f to $BACKUP_DIR/$f"
  DOTFILE_SYMLINK_INSTALL="Creating symlink from $HOME/$f to $SCRIPT_HOME/$f"
  # Backup any existing config files if present and not already backed up
  if [ -e $HOME/$f ]; then
    if mv $HOME/$f $BACKUP_DIR/$f; then
      log "${TICK} $DOTFILE_BACKUP_INSTALL"
    else
      log "${CROSS} $DOTFILE_BACKUP_INSTALL failed"
      # ToDo: Any error handling here?
    fi
  fi

  # Symlinking config file from git source directory
  if ln -sf $SCRIPT_HOME/$f $HOME/$f; then
    log "${TICK} $DOTFILE_SYMLINK_INSTALL"
  else
    log "${CROSS} $DOTFILE_SYMLINK_INSTALL failed"
  fi
done

##############################################################################
# Configure git user name
GIT_CUR_NAME=$(git config --global user.name)
GIT_NAME_INSTALL="Setting git name ($GIT_NEW_NAME)"
if [ -z "$GIT_CUR_NAME" ]; then
  if git config --global user.name "$GIT_NEW_NAME"; then	
    log "${TICK} $GIT_NAME_INSTALL"
  else
    log "${CROSS} $GIT_NAME_INSTALL failed"
  fi
else
  log "${INFO} $GIT_NAME_INSTALL skipped, $GIT_CUR_NAME already defined"
fi

##############################################################################
# Configure git user email
GIT_CUR_EMAIL=$(git config --global user.email)
GIT_EMAIL_INSTALL="Setting git email ($GIT_NEW_EMAIL)"
if [ -z "$GIT_CUR_EMAIL" ]; then
  if git config --global user.email "$GIT_NEW_EMAIL"; then	
    log "${TICK} $GIT_EMAIL_INSTALL"
  else
    log "${CROSS} $GIT_EMAIL_INSTALL failed"
  fi
else
  log "${INFO} $GIT_EMAIL_INSTALL skipped, $GIT_CUR_EMAIL already defined"
fi

GIT_CUR_NAME=$(git config --global user.name)
GIT_CUR_EMAIL=$(git config --global user.email)
log "${TICK} Git global configuration ($GIT_CUR_NAME <$GIT_CUR_EMAIL>)"

##############################################################################
# Configure git "fixline" alias for DPDK
GIT_FIXLINE_INSTALL="Setting git fixline alias"
if git config alias.fixline "log -1 --abbrev=12 --format='Fixes: %h (\"%s\")%nCc: %ae'"; then
  log "${TICK} $GIT_FIXLINE_INSTALL"
else
  log "${CROSS} $GIT_FIXLINE_INSTALL failed"
fi

##############################################################################
# Configure git pull mode
GIT_PULL_FF_INSTALL="Setting git pull mode to fast-forward"
if git config --global pull.ff only; then
  log "${TICK} $GIT_PULL_FF_INSTALL"
else
  log "${CROSS} $GIT_PULL_FF_INSTALL failed"
fi

##############################################################################
# Configure git default branch name
GIT_DEF_BRANCH_NAME="Setting git default branch name to main"
if git config --global init.defaultBranch main; then
  log "${TICK} $GIT_DEF_BRANCH_NAME"
else
  log "${CROSS} $GIT_DEF_BRANCH_NAME failed"
fi

log "${TICK} Setup complete, logout/login to enable changes"

##############################################################################
# ToDo: Any error checking here?
# ToDo: Source the new configuration now?
# ToDo: What if powerline installed system-wide??  How to handle?
