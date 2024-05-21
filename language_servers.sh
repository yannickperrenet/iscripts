#!/bin/sh

node_install() {
    curl -sL https://deb.nodesource.com/setup_20.x | sudo -E bash -
    sudo apt install -y nodejs >/dev/null 2>&1
}

# Make sure node is installed.
[ -z $(command -v node) ] && node_install

# Install the language servers
# Python
sudo npm install -g pyright
# Typescript
sudo npm install -g typescript typescript-language-server
# C
sudo apt-get install -y clangd
# Rust
rustup component add rust-src rust-analyzer
