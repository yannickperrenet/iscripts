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

    # Install pip3 if it is not yet installed.
    [ -x "$(command -v "pip3")" ] || installpkg python3-pip > /dev/null 2>&1

    # Install the Python package without prompting the user for
    # confirmation.
    yes | pip3 install "$1"
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
for x in curl git zsh; do
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
dfg update-index --assume-unchanged "/home/$USER/README.md" "/home/$USER/LICENSE"

# Make zsh the default shell for the user.
sudo chsh -s /bin/zsh "$USER" > /dev/null 2>&1
sudo -u "$USER" mkdir -p "/home/$USER/.cache/zsh/"

# If specified, then install language servers.
[ "$lsp" ] && sh language_servers.sh
