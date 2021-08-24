dotfiles
========

Cross Platform Initialization Files

Uses powerline to setup bash, vim, and tmux.

Tested distributions:
 - [ ] CentOS 7.x
 - [x] CentOS 8.x
 - [x] Debian 9 (Stretch)
 - [x] Debian 10 (Buster)
 - [x] Debian 11 (Bullseye)
 - [ ] Red Hat Enterprise Linux 7.x
 - [x] Red Hat Enterprise Linux 8.3
 - [x] Red Hat Enterprise Linux 8.4
 - [ ] Ubuntu 16.04 (Xenial Xerus)
 - [x] Ubuntu 18.04 (Bionic Beaver)
 - [x] Ubuntu 20.04 (Focal Fossa)
 - [x] Ubuntu 21.04 (Hirsute Hippo)

ToDo:
 - [ ] Test with system-wide powerline installation
 - [x] RHEL 8.4 uses python3.8 for python3 but vim uses python3.6, so installing powerline module is not visible to vim from python3.8 site-packages.  Workaround is to also install powerline with the command "python3.6 -m pip install --user powerline-status powerline-gitstatus".  Figure out how to test with setup.sh script.
