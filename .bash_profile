if [ -f ~/.bashrc ]; then
	  . ~/.bashrc
fi

# Load and install iterm2 shell integration if present
test -e "${HOME}/.iterm2_shell_integration.bash" && source "${HOME}/.iterm2_shell_integration.bash"
