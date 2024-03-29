# Git shortcuts
gitdone() {
  git add -A
  git commit -S -v -m "$1"
  git push
}

function gitl() {
  git log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit
}

# Use ssht to open tmux automatically for ssh sessions
function ssht() {
  ssh $* -t 'tmux a || tmux || /bin/bash'
}

# Dave's custom aliases
# alias sudo="sudo "
# alias yum='FTP3USER=$FTP3USER FTP3PASS=$FTP3PASS $HOME/.local/bin/ibm-yum.sh'
alias hg="history | grep -i "

# DPDK aliases
alias rte=_rte $@
alias bld=_bld $@
alias dbld=_dbld $@

# Microk8s aliases
alias mkctl="microk8s kubectl"

# Use Vagrant with libvirt on Ubuntu
# See https://github.com/vagrant-libvirt/vagrant-libvirt#using-docker-based-installation
alias vagrant='
  mkdir -p ~/.vagrant.d/{boxes,data,tmp}; \
  docker run -it --rm \
    -e LIBVIRT_DEFAULT_URI \
    -v /var/run/libvirt/:/var/run/libvirt/ \
    -v ~/.vagrant.d:/.vagrant.d \
    -v $(pwd):$(pwd) \
    -w $(pwd) \
    --network host \
    vagrantlibvirt/vagrant-libvirt:latest \
    vagrant'
