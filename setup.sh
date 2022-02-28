#!/bin/bash

# set -x

# Make sure we're running as root
[ ! "$EUID" -eq 0 ] && echo "Rerun script with \"sudo $0 $@\"" && exit 1

##############################################################################
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

##############################################################################
# Pyenv build requirements
# https://github.com/pyenv/pyenv/wiki#suggested-build-environment
##############################################################################
UBUNTU_PACKAGES=("wget" "mc" "python3" "python3-pip" "tmux" "exuberant-ctags" "vim" "curl" "make" "build-essential" "libssl-dev" "zlib1g-dev" "libbz2-dev" "libreadline-dev" "libsqlite3-dev" "wget" "curl" "llvm" "libncursesw5-dev" "xz-utils" "tk-dev" "libxml2-dev" "libxmlsec1-dev" "libffi-dev" "liblzma-dev")
DEBIAN_PACKAGES=("wget" "mc" "python3" "python3-pip" "tmux" "exuberant-ctags" "vim-nox" "curl" "make" "build-essential" "libssl-dev" "zlib1g-dev" "libbz2-dev" "libreadline-dev" "libsqlite3-dev" "wget" "curl" "llvm" "libncursesw5-dev" "xz-utils" "tk-dev" "libxml2-dev" "libxmlsec1-dev" "libffi-dev" "liblzma-dev")
RPM_PACKAGES=("wget" "mc" "python3" "python3-pip" "tmux" "ctags" "vim" "curl" "zlib-devel" "bzip2" "bzip2-devel" "readline-devel" "sqlite" "sqlite-devel" "openssl-devel" "tk-devel" "libffi-devel" "xz-devel")
BREW_PACKAGES=("tmux" "curl" "openssl" "readline" "sqlite3" "xz" "zlib")
GROUP_PACKAGES=("Development tools")

##############################################################################
# Install requirements for the distro
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
  case $ID in
    ubuntu) apt install -y ${UBUNTU_PACKAGES[@]} || exit 1;;
    debian) apt install -y ${DEBIAN_PACKAGES[@]} || exit 1;;
    centos | fedora | rhel) dnf install -y ${RPM_PACKAGES[@]} && dnf groupinstall -y "${GROUP_PACKAGES[@]}";;
  esac
elif [[ "$OSTYPE" == "darwin"* ]]; then
  brew install -y ${BREW_PACKAGES[@]} || exit 1
fi

# Let the config.sh script know that we ran successfully
touch .setup_completed
