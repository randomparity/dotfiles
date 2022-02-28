dotfiles
========

Cross Platform Initialization Files

Sets up powerline for bash, vim, and tmux. Customize git and add other shell settings.

Tested distributions:
 - [ ] CentOS 7.x
 - [x] CentOS 8.x
 - [x] CentOS 8 Stream
 - [x] Fedora 34
 - [x] Fedora 35
 - [ ] Debian 9 (Stretch)
 - [ ] Debian 10 (Buster)
 - [x] Debian 11 (Bullseye)
 - [ ] Red Hat Enterprise Linux 7.x
 - [ ] Red Hat Enterprise Linux 8.3
 - [ ] Red Hat Enterprise Linux 8.4
 - [ ] Ubuntu 16.04 (Xenial Xerus)
 - [x] Ubuntu 18.04 (Bionic Beaver)
 - [x] Ubuntu 20.04 (Focal Fossa)
 - [ ] Ubuntu 21.04 (Hirsute Hippo)
 - [ ] Ubuntu 21.10 ()
 - [ ] Ubuntu 22.04 ()

ToDo:
 - [ ] Test with system-wide powerline installation
 - [x] RHEL 8.4 uses python3.8 for python3 but vim uses python3.6, so installing powerline module is not visible to vim from python3.8 site-packages.  Workaround is to also install powerline with the command "python3.6 -m pip install --user powerline-status powerline-gitstatus".  Figure out how to test with setup.sh script.
 - [ ] Add MacOS support
 - [x] Add pyenv support
 - [x] Add support for multiple config file backups
 - [x] Enable logging for setup and config script
 - [ ] Debug error code in prompt on login
 - [ ] Figure out how to setup locale (see [here](https://www.emeralddesign.com/index.php/2019/05/28/lxc-containers-and-language-locale/))
