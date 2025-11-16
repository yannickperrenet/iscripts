#!/bin/sh

### OPTIONS AND VARIABLES ###

printhelp() {
# `cat << EOF` means that cat should stop reading when EOF is detected.
cat << EOF
Optional arguments for custom use:

-h      Display this message.
-p      Dependencies and programs csv (local file).
-l      Specify to also install language servers.

EOF

# Exit once we have printed the help message.
exit 1
}

while getopts ":hp:l" opt; do
    case $opt in
        h) printhelp ;;
        p) progsfile=${OPTARG} ;;
        l) lsp=true ;;
    esac
done

[ -z "$progsfile" ] && progsfile="progs.csv"
[ -z "$dotfilesrepo" ] && dotfilesrepo="https://github.com/yannickperrenet/dotfiles.git"

### FUNCTIONS ###

installpkg() {
    sudo apt install -y $1 > /dev/null 2>&1
}

maininstall() {
    echo "Installing \`$1\` ($n of $total). $1 $2"
    installpkg "$1"
}

pipinstall() {
    echo "Installing the Python package \`$1\` ($n of $total). $1 $2"

    # Install the Python package without prompting the user for
    # confirmation.
    yes | pipx install "$1"
}

pipxinject() {
    echo "Installing the Python package \`$1\` ($n of $total). $1 $2"

    # Install the Python package without prompting the user for
    # confirmation.
    yes | pipx inject "$2" "$1"
}

progsinstallation() {
    # Get the progsfile and delete the header.
    [ -f "$progsfile" ] && cat "$progsfile" | sed '/^#/d' > /tmp/progs.csv

    total=$(wc -l < /tmp/progs.csv)

    # Use , as the delimeter.
    while IFS=, read -r tag program comment; do
        # Indication of how many programs we have installed so far.
        n=$((n+1))

        # Remove the "" from the comment.
        comment="$(echo "$comment" | sed "s/\(^\"\|\"$\)//g")"

        case "$tag" in
            "P") pipinstall "$program" "$comment" ;;
            "PI") pipxinject "$program" "$comment" ;;
            *) maininstall "$program" "$comment" ;;
        esac
    done < /tmp/progs.csv
}

putgitrepo() { # Downloads a gitrepo $1 and places the files in $2 only overwriting conflicts
    # Create a temporary directory and the destination directory, and
    # make sure they are owned by the current user.
	dir=$(mktemp -d)
    [ ! -d "$2" ] && mkdir -p "$2"
    chown -R "$USER":"$USER" "$dir" "$2"

	sudo -u "$USER" git clone --recursive --recurse-submodules "$1" "$dir" > /dev/null 2>&1
	sudo -u "$USER" cp -rfT "$dir" "$2" >/dev/null 2>&1
}

### THE ACTUAL SCRIPT ###

# Build dependencies.
for x in curl git zsh make; do
	echo "Installing \`$x\` which is required to install and configure other programs."
	installpkg "$x"
done

# Install the programs from the progsfile.
progsinstallation

# Install the dotfiles in the user's home directory.
echo "Installing dotfiles..."
# putgitrepo "$dotfilesrepo" "/home/$USER"
# Setup a bare git repository to manage the dotfiles
git clone --bare --config status.showUntrackedFiles=no "$dotfilesrepo" "/home/$USER/.local/share/dotfiles"
alias dfg="/usr/bin/git --git-dir=/home/$USER/.local/share/dotfiles --work-tree=/home/$USER"
# Setup all the files.
dfg checkout -f
# Initialize the submodules, which has to be done like this in order for
# the bare repository to be able to manage them.
dfg submodule update --init --recursive
# Delete files, but make git ignore the deletion. The files can simply
# be restored with e.g. `dfg checkout README.md`.
rm -f "/home/$USER/README.md" "/home/$USER/LICENSE"
dfg update-index --assume-unchanged \
    "/home/$USER/README.md" \
    "/home/$USER/LICENSE" \
    "/home/$USER/.config/gtk-3.0/settings.ini" \
    "/home/$USER/.local/share/redshift/current_period" \
    "/home/$USER/.config/alacritty/alacritty.toml"

# Make zsh the default shell for the user.
sudo chsh -s /bin/zsh "$USER" > /dev/null 2>&1
sudo -u "$USER" mkdir -p "/home/$USER/.cache/zsh/"

# Now that we have the dotfiles, load profile to set env vars.
. "/home/$USER/.profile"

# ----- Manual configuration
# Disable connectivity pings
sudo cp /home/$USER/.local/share/NetworkManager/disable-check.conf /etc/NetworkManager/conf.d/
sudo service NetworkManager restart
# Custom names for my SSDs
sudo cp /home/sven/.local/share/udev/10-mydrives.rules /etc/udev/rules.d/
# Set up crontabs from dotfiles repo
crontab /home/$USER/.local/share/crontab/user
sudo crontab -u clamav /home/$USER/.local/share/crontab/clamav

# Install programming languages that are needed later.
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
rustup default stable

# If specified, then install language servers.
[ "$lsp" ] && sh language_servers.sh

# ----- Application specific installation
# See: https://github.com/jonls/redshift/issues/850
[ -e "/etc/apparmor.d/local/usr.bin/redshift" ] && sudo rm /etc/apparmor.d/local/usr.bin.redshift
[ -e "/etc/apparmor.d/usr.bin.redshift" ] && sudo rm /etc/apparmor.d/usr.bin.redshift
sudo systemctl reload apparmor.service
# Remove Gnome Display Manager and start on a tty instead
sudo apt-get remove -y gdm3
# Get dptfxtract to set up thermald config. However, don't decide for
# the user and don't execute it. The increased performance will
# generate more heat and thus make the fan spin harder.
wget --directory-prefix /home/$USER/.local/bin -q https://github.com/intel/dptfxtract/raw/master/dptfxtract
chmod +x /home/$USER/.local/bin/dptfxtract
# Nvim
wget --directory-prefix /home/$USER/Downloads -q https://github.com/neovim/neovim/releases/download/v0.11.4/nvim-linux-x86_64.tar.gz
tar xzvf /home/$USER/Downloads/nvim-linux-x86_64.tar.gz -C /home/$USER/.local/ --strip-components 1
# Alacritty.
sudo apt-get install -y cmake g++ pkg-config libfontconfig1-dev libxcb-xfixes0-dev libxkbcommon-dev python3
cd /home/$USER/.opt/alacritty  # path exists in dotfiles repo
cargo build --release
sudo tic -xe alacritty,alacritty-direct extra/alacritty.info
sudo cp target/release/alacritty /home/$USER/.local/bin
sudo cp extra/logo/alacritty-term.svg /usr/share/pixmaps/Alacritty.svg
sudo desktop-file-install extra/linux/Alacritty.desktop
sudo update-desktop-database
# Zotero: https://www.zotero.org/support/installation
# mkdir /home/$USER/.opt/zotero && cd /home/$USER/.opt/zotero
# tar xjvf Zotero-7.0.11_linux-x86_64.tar.bz2 -C ~/.opt/zotero --strip-components 1
# ./set_launcher_icon
# ln -s /home/$USER/.opt/zotero/zotero.desktop ~/.local/share/applications/zotero.desktop
