dotfiles
========

Cross Platform Initialization Files

Sets up powerline for bash, vim, and tmux. Customize git and add other shell settings.

Tested distributions:
 - [ ] CentOS 7.x
 - [x] CentOS 8.x
 - [x] CentOS 8 Stream
 - [ ] CentOS 9 Stream
 - [x] Fedora 34
 - [x] Fedora 35
 - [ ] Debian 9 (Stretch)
 - [ ] Debian 10 (Buster)
 - [x] Debian 11 (Bullseye)
 - [ ] Red Hat Enterprise Linux 7.x
 - [ ] Red Hat Enterprise Linux 8.3
 - [ ] Red Hat Enterprise Linux 8.4
 - [ ] Red Hat Enterprise Linux 8.5
 - [ ] Red Hat Enterprise Linux 9
 - [ ] Ubuntu 16.04 (Xenial Xerus)
 - [x] Ubuntu 18.04 (Bionic Beaver)
 - [x] Ubuntu 20.04 (Focal Fossa)
 - [ ] Ubuntu 21.04 (Hirsute Hippo)
 - [ ] Ubuntu 21.10 (Impish Indri)
 - [ ] Ubuntu 22.04 (Jammy Jellyfish)

ToDo:
 - [ ] Test with system-wide powerline installation
 - [x] RHEL 8.4 has a different version of python for the system and vim. Install two powerline instances, one for each version.
 - [ ] CentOS 7 does not support python3 in vim (python -V is 2.7.5 in CentOS 7.9)
 - [ ] Add MacOS support
 - [x] Add pyenv support
 - [x] Add support for multiple config file backups
 - [x] Enable logging for setup and config script
 - [ ] Debug error code in prompt on login
 - [ ] Figure out how to setup locale (see [here](https://www.emeralddesign.com/index.php/2019/05/28/lxc-containers-and-language-locale/) and [here](https://askubuntu.com/questions/162391/how-do-i-fix-my-locale-issue))
