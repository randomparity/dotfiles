#!/bin/bash

# set -x

###########################################################
# Customizations (Begin)
###########################################################
PYENV_PYTHON_VER="3.10.4"
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
LOG_DIR=$SCRIPT_HOME/logs
LOG_FILE=$LOG_DIR/config.$NOW.log
BACKUP_DIR=$SCRIPT_HOME/backups/$NOW
mkdir -p $LOG_DIR
mkdir -p $BACKUP_DIR

# Function to write status to the console and a log file
log() {
  echo -e "$@" 1> >(tee -a $LOG_FILE) 2> >(tee -a $LOG_FILE >&2)
  # ToDo: Figure out how to strip ANSI sequences from log file
  # https://superuser.com/questions/380772/removing-ansi-color-codes-from-text-stream
  # echo -e "$@" | sed 's/\x1b\[[0-9;]*m//g' | tee -a $LOG_FILE
  # perl -pe ' s/\e\[[\x30-\x3f]*[\x20-\x2f]*[\x40-\x7e]//g; s/\e[PX^_].*?\e\\//g; s/\e\][^\a]*(?:\a|\e\\)//g; s/\e[\[\]A-Z\\^_@]//g;'
}

# Function to echo commands to log file as they are executed
exe() {
  params=("$@")
  # Print the command and parameters to the log file
  printf "%s\t%q" "$(date)" "${params[0]}" >> "$LOG_FILE"
  printf " %q" "${params[@]:1}"            >> "$LOG_FILE"
  printf "\n"                              >> "$LOG_FILE"
  # Execute the command and log the output
  "${params[@]}" >> $LOG_FILE 2>&1
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

##############################################################################
# Block install on known unsupported OS distros
# - CentOS Linux 7 (Core) [centos]
case $ID in
  centos | rhel) [[ $VER = "7 (Core)" ]] && log "${CROSS} $OS $VER not currently supported" && exit 1
esac

##############################################################################
# Check if setup.sh has run to install pre-requisites
CHECK_REQS_TXT="Checking for pre-requisites"
if [[ -f .setup_completed ]]; then log "${TICK} $CHECK_REQS_TXT"; else log "${CROSS} $CHECK_REQS_TXT"; exit 1; fi

##############################################################################
# Fetch system and vim python versions
SYS_PYTHON_VER=$(python3 --version 2>&1 | grep -Po '(?<=^Python )[0-9]*.[0-9]*(?=.[0-9A-Za-z-]*)')
VIM_PYTHON_VER=$(vim --version | grep -Po '^Compilation:.*[-/Ia-z]+python\K(3\.\d+)|Linking:.*[-a-z]python\K(3\.\d+)')
log "${INFO} System python version: python$SYS_PYTHON_VER"
log "${INFO} Vim python version   : python$VIM_PYTHON_VER"

##############################################################################
# Install pyenv
PYENV_INSTALL_TXT="Installing pyenv"
if [[ ! -f $HOME/.pyenv/bin/pyenv ]]; then
  # ToDo: How to log results here
  curl https://pyenv.run | bash
fi

##############################################################################
# Verify that pyenv is installed
PYENV_CHECK_TXT="Checking pyenv"
if [[ -x $HOME/.pyenv/bin/pyenv ]]; then log "${TICK} $PYENV_CHECK_TXT"; else log "${CROSS} $PYENV_CHECK_TXT"; exit 1; fi

##############################################################################
# Setup pyenv environment
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"

# https://github.com/pyenv/pyenv/issues/1906
# eval "$(pyenv init -)"
eval "$(pyenv init --path)"
eval "$(pyenv virtualenv-init -)"
# ToDo: What if pyenv already installed and a non-system python is selected?

##############################################################################
# Install a local python version
log "${INFO} Preparing local python $PYENV_PYTHON_VER"
PYTH_INSTALL_TXT="Installing python $PYENV_PYTHON_VER"
exe pyenv install -s $PYENV_PYTHON_VER
if [[ $? -eq 0 ]]; then log "${TICK} $PYTH_INSTALL_TXT"; else log "${CROSS} $PYTH_INSTALL_TXT"; exit 1; fi

##############################################################################
# Set the default python version
PYTH_SELECT_TXT="Selecting local python $PYENV_PYTHON_VER"
exe pyenv global $PYENV_PYTHON_VER
if [[ $? -eq 0 ]]; then log "${TICK} $PYTH_SELECT_TXT"; else log "${CROSS} $PYTH_SELECT_TXT"; exit 1; fi

##############################################################################
# Report the current python version
CURR_PYTHON_VER=$(python3 -c 'import sys; print(".".join(map(str, sys.version_info[0:2])))')
CURR_PYTHON_TXT="Current python3 is $CURR_PYTHON_VER"
log "${INFO} $CURR_PYTHON_TXT"

##############################################################################
# Fetch a copy of pip for our local python version
# https://bootstrap.pypa.io/pip/get-pip.py
# https://bootstrap.pypa.io/pip/3.6/get-pip.py
PIP_FETCH_TXT="Fetching bootstrap pip installer"
exe wget https://bootstrap.pypa.io/get-pip.py
if [[ $? -eq 0 ]]; then log "${TICK} $PIP_FETCH_TXT"; else log "${CROSS} $PIP_FETCH_TXT"; exit 1; fi

##############################################################################
# Install a copy of pip for our local python version
PIP_INSTALL_TXT="Installing pip locally"
exe python3 get-pip.py
if [[ $? -eq 0 ]]; then log "${TICK} $PIP_INSTALL_TXT"; else log "${CROSS} $PIP_INSTALL_TXT"; exit 1; fi
exe rm get-pip.py.*

##############################################################################
# Install powerline for bash shell
POWERLINE_SYS_INSTALL="Installing powerline for bash"
exe python3 -m pip install --user powerline-status powerline-gitstatus
if [[ $? -eq 0 ]]; then log "${TICK} $POWERLINE_SYS_INSTALL"; else log "${CROSS} $POWERLINE_SYS_INSTALL"; exit 1; fi

##############################################################################
# Install powerline for vim
POWERLINE_VIM_INSTALL="Installing powerline for vim"
exe pip$VIM_PYTHON_VER install --user powerline-status powerline-gitstatus
if [[ $? -eq 0 ]]; then log "${TICK} $POWERLINE_VIM_INSTALL"; else log "${CROSS} $POWERLINE_VIM_INSTALL"; exit 1; fi

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
  ln -sf "$SCRIPT_HOME/powerline" "$HOME/.config/powerline"
  if [[ $? -eq 0 ]]; then log "${TICK} $POWERLINE_SYMLINK_INSTALL"; else log "${CROSS} $POWERLINE_SYMLINK_INSTALL"; fi
fi

##############################################################################
# Symlink new dotfiles to the home directory
for f in .vimrc .bashrc .bash_aliases .bash_profile .tmux.conf .gdbinit .dircolors; do
  DOTFILE_BACKUP_INSTALL="Backing up $HOME/$f to $BACKUP_DIR/$f"
  DOTFILE_SYMLINK_INSTALL="Symlinking $HOME/$f to $SCRIPT_HOME/$f"
  # Backup any existing config files if present and not already backed up
  if [ -e $HOME/$f ]; then
    mv $HOME/$f $BACKUP_DIR/$f
    if [[ $? -eq 0 ]]; then log "${TICK} $DOTFILE_BACKUP_INSTALL"; else log "${CROSS} $DOTFILE_BACKUP_INSTALL failed"; fi
  fi

  # Symlinking config file from git source directory
  ln -sf $SCRIPT_HOME/$f $HOME/$f
  if [[ $? -eq 0 ]]; then log "${TICK} $DOTFILE_SYMLINK_INSTALL"; else log "${CROSS} $DOTFILE_SYMLINK_INSTALL failed"; fi
done

##############################################################################
# Configure git user name
GIT_CUR_NAME=$(git config --global user.name)
GIT_NAME_INSTALL="Setting git name ($GIT_NEW_NAME)"
git config --global user.name "$GIT_NEW_NAME"
if [[ $? -eq 0 ]]; then log "${TICK} $GIT_NAME_INSTALL"; else log "${CROSS} $GIT_NAME_INSTALL failed"; fi

##############################################################################
# Configure git user email
GIT_CUR_EMAIL=$(git config --global user.email)
GIT_EMAIL_INSTALL="Setting git email ($GIT_NEW_EMAIL)"
git config --global user.email "$GIT_NEW_EMAIL"
if [[ $? -eq 0 ]]; then	log "${TICK} $GIT_EMAIL_INSTALL"; else log "${CROSS} $GIT_EMAIL_INSTALL failed"; fi

##############################################################################
# Configure git "fixline" alias for DPDK
GIT_FIXLINE_INSTALL="Setting git fixline alias"
git config alias.fixline "log -1 --abbrev=12 --format='Fixes: %h (\"%s\")%nCc: %ae'"
if [[ $? -eq 0 ]]; then log "${TICK} $GIT_FIXLINE_INSTALL"; else log "${CROSS} $GIT_FIXLINE_INSTALL failed"; fi

##############################################################################
# Configure git pull mode
GIT_PULL_FF_INSTALL="Setting git pull mode to fast-forward"
git config --global pull.ff only
if [[ $? -eq 0 ]]; then log "${TICK} $GIT_PULL_FF_INSTALL"; else log "${CROSS} $GIT_PULL_FF_INSTALL failed"; fi

##############################################################################
# Configure git default branch name
GIT_DEF_BRANCH_NAME="Setting git default branch name to main"
git config --global init.defaultBranch main
if [[ $? -eq 0 ]]; then log "${TICK} $GIT_DEF_BRANCH_NAME"; else log "${CROSS} $GIT_DEF_BRANCH_NAME failed"; fi

##############################################################################
# Configure git push behavior
GIT_DEF_PUSH="Setting git default push behavior"
git config --global push.default simple
if [[ $? -eq 0 ]]; then log "${TICK} $GIT_DEF_PUSH"; else log "${CROSS} $GIT_DEF_PUSH failed"; fi

log "${TICK} Setup complete, logout/login to enable changes"

##############################################################################
# ToDo: Any error checking here?
# ToDo: Source the new configuration now?
# ToDo: What if powerline installed system-wide??  How to handle?
