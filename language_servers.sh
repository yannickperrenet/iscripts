#!/bin/sh

node_install() {
    curl -sL https://deb.nodesource.com/setup_24.x | sudo -E bash -
    sudo apt install -y nodejs >/dev/null 2>&1
}

# Make sure node is installed.
[ -z $(command -v node) ] && node_install

# Install the language servers
# Python
npm install -g pyright
# Typescript & Vue
npm install -g typescript typescript-language-server
npm install -g @vue/language-server @vue/typescript-plugin
# C
sudo apt-get install -y clangd
# Rust
rustup component add rust-src rust-analyzer
