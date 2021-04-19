#!/bin/bash

# Store where the script was called from so we can reference it later
SCRIPT_HOME="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source COLOR_TABLE

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


# Check for important packages
PACKAGES=()
if ! command -v curl &> /dev/null; then
  echo -e "${CROSS} Curl check"
  PACKAGES+=("curl")
else
  echo -e "${TICK} Curl check"
fi

if ! command -v vim &> /dev/null; then
  echo -e "${CROSS} Vim check"
  PACKAGES+=("vim")
else
  echo -e "${TICK} Vim check"
fi

if ! command -v ctags &> /dev/null; then
  echo -e "${CROSS} Ctags check"
  if [ $ID == "centos" ]; then
    PACKAGES+=("ctags")
  elif [ $ID == "ubuntu" ]; then
    PACKAGES+=("exuberant-ctags")
  fi
  # ToDo: What to do for other distros??
else
  echo -e "${TICK} Ctags check"
fi

if ! command -v tmux &> /dev/null; then
  echo -e "${CROSS} Tmux check"
  PACKAGES+=("tmux")
else
  echo -e "${TICK} Tmux check"
fi

if ! command -v python3 &> /dev/null; then
  echo -e "${CROSS} Python3 check"
  PACKAGES+=("python3")
else
  echo -e "${TICK} Python3 check"
fi

if ! command -v pip3 &> /dev/null; then
  echo -e "${CROSS} Pip3 check"
  PACKAGES+=("python3-pip")
else
  echo -e "${TICK} Pip3 check"
fi

# ToDo: Give option to install here
if (( ${#PACKAGES[@]} > 0 )); then
  if [ $ID == "centos" ]; then
    echo -e "${INFO} Run 'sudo yum install -y ${PACKAGES[@]}'"
    exit 1
  elif [ $ID == "ubuntu" ]; then
    echo -e "${INFO} Run 'sudo apt install -y ${PACKAGES[@]}'"
    exit 1
  fi
fi

# Known dependencies met, install powerline and symlink config files
# ToDo: Check for install error here
if python3 -m pip install --user powerline-status powerline-gitstatus &> /dev/null; then
  echo -e "${TICK} Powerline install"
else
  echo -e "${CROSS} Powerline install"
  echo "  Run 'python3 -m pip install --user powerline-status powerline-gitstatus' manually"
  exit 1
fi

# Symlink powerline into the .config directoy
[ ! -d "$HOME/.config" ] && mkdir -p "$HOME/.config"
# ToDo: Progress message here
# ToDo: What if an existing file in this location?
[ -d "$HOME/.config/powerline" ] && mv "$HOME/.config/powerline" "$HOME/.config/powerline.backup"
# ToDo: Progress message here
if ln -sf "$SCRIPT_HOME/powerline" "$HOME/.config/powerline"; then
  echo -e "${TICK} Symlink $SCRIPT_HOME/powerline to $HOME/.config/powerline"
else
  echo -e "${CROSS} Symlink $SCRIPT_HOME/powerline to $HOME/.config/powerline"
fi

# Symlink all of our dotfiles to the home directory
for f in .vimrc .bashrc .bash_aliases .bash_profile .tmux.conf .gdbinit .dircolors;
do
  # ToDo: How to handle pre-existing .backup files?
  [ -e $HOME/$f ] && mv $HOME/$f $HOME/$f.backup
  if ln -sf $SCRIPT_HOME/$f $HOME/$f; then
    echo -e "${TICK} Symlink $SCRIPT_HOME/$f to $HOME/$f"
  else
    echo -e "${CROSS} Symlink $SCRIPT_HOME/$f to $HOME/$f"
  fi
done

# Add git global configuration settings
# ToDo: Add error checking here
git config --global user.email "randomparity@gmail.com"
git config --global user.name "David Christensen"
echo -e "${TICK} Git global configuration (David Christensen <randomparity@gmail.com>)"

# ToDo: Any error checking here?

# ToDo: Source the new configuration now?
echo -e "${TICK} Setup complete, logout/login to enable changes"

# ToDo: Why does script create ~/src/dotfiles/powerline/powerline symlink?
