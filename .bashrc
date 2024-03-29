# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=10000
HISTFILESIZE=20000
HISTIGNORE="history:pwd:exit:df:ls:ls -alh:ll"

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
#shopt -s globstar

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
  debian_chroot=$(cat /etc/debian_chroot)
fi

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
  xterm-color|*-256color) color_prompt=yes;;
esac

# uncomment for a colored prompt, if the terminal has the capability; turned
# off by default to not distract the user: the focus in a terminal window
# should be on the output of commands, not on the prompt
#force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
	# We have color support; assume it's compliant with Ecma-48
	# (ISO/IEC-6429). (Lack of such support is extremely rare, and such
	# a case would tend to support setf rather than setaf.)
	color_prompt=yes
    else
	color_prompt=
    fi
fi

if [ "$color_prompt" = yes ]; then
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt

# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
*)
    ;;
esac

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# colored GCC warnings and errors
#export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# some more ls aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# Enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

##############################################################################
# DRC - Local changes start here
##############################################################################
export EDITOR=vim

##############################################################################
# Initial PATH setup
export PATH="$HOME/.local/bin:$HOME/bin:$PATH"

# Get Brew in the path early for MacOS
if [ -x /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

##############################################################################
# Setup pyenv environment early
if [[ -x $HOME/.pyenv/bin/pyenv ]]; then
  export PYENV_ROOT=$HOME/.pyenv
  export PATH="$PYENV_ROOT/bin:$PATH"
  [ -f $PYENV_ROOT/version ] && export PYENV_VERSION=$(cat $PYENV_ROOT/version)
  eval "$(pyenv init -)"
  eval "$(pyenv virtualenv-init -)"
fi

##############################################################################
# Setup powerline if installed
if [[ -x $(command -v python3) ]]; then
  export POWERLINE_SITE_PATH=`python3 -c "import powerline as _; print(_.__path__[0])"`
  if [[ -n $POWERLINE_SITE_PATH && -x $(command -v powerline-daemon) ]]; then
    powerline-daemon --quiet
    if [[ -f $POWERLINE_SITE_PATH/bindings/bash/powerline.sh ]]; then
      source $POWERLINE_SITE_PATH/bindings/bash/powerline.sh
      # Need these for tmux
      POWERLINE_CONFIG_COMMAND=powerline-config
      POWERLINE_BASH_CONTINUATION=1
      POWERLINE_BASH_SELECT=1
    fi
  fi
fi

##############################################################################
# Linux specific customizations
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
  true
  # Additional linux commands here

##############################################################################
# MacOS specific customizations
elif [[ "$OSTYPE" == "darwin"* ]]; then

  # Setup alias for vim installed by brew
  if (command -v brew && brew list --formula | grep -c vim ) > /dev/null 2>&1; then
    alias vim="$(brew --prefix vim)/bin/vim"
  fi

  # Setup alias for running GUI diff app from the command line
  # ToDo: How to detect GUI diff application?
  alias vdiff="open -a CompareMerge2 "

  # Disable MacOS nagging about zsh
  export BASH_SILENCE_DEPRECATION_WARNING=1
fi

##############################################################################
# Configure go (if present)
if command -v go >/dev/null 2>&1; then
  export GOPATH=$(go env GOPATH)
  mkdir -p $HOME/go/{bin,src}
  export PATH=$PATH:$GOPATH/bin
fi

##############################################################################
# Enable direnv (https://direnv.net/docs/hook.html says it must be last)
if command -v direnv > /dev/null 2>&1; then
  eval "$(direnv hook bash)"
fi

##############################################################################
# Setup PYTHONPATH to ensure vim finds powerline module
PYTHONPATH="$(python3 -m site --user-site):$PYTHONPATH"

# Ensure the last statement doesn't produce a non-zero exit code
# true
