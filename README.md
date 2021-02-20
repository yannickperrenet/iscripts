# iscripts

> Special thanks to [LukeSmithxyz/LARBS](https://github.com/LukeSmithxyz/LARBS)

Installation scripts for my Ubuntu installation.

## Installation
```bash
git clone https://github.com/yannickperrenet/iscripts.git && cd iscripts

# Delete the `-l` option to not install language-servers.
sh install.sh -l
```

For a complete step-by-step process to set up everything, see the `INSTALL.md` file.

## Programs
All programs listed in `progs.csv` are installed automatically through the `install.sh` script.

Programs in `manual-progs.csv` have to be installed manually as I do not want to install packages
using `snap`. Secondly, some of these programs are proprietary and therefore I don't want to be
installing them by default (only for things like work).
