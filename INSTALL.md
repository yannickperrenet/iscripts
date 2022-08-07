# Step-by-step installation

On a fresh installation, take the following steps to end up with my configurations:

1. Install git.
   ```sh
   sudo apt install -y git
   ```
2. Clone the repo
   ```sh
   mkdir -p ~/.opt/iscripts \
       && git clone https://github.com/yannickperrenet/iscripts.git ~/.opt/iscripts \
       && cd ~/.opt/iscripts
   ```
3. Run the installation script
   ```sh
   # Delete the `-l` option to not install language-servers.
   sh install.sh -l
   ```
4. Reboot. You should now automatically go to `tty1` to log in as there no longer is a display
   manager installed.
5. Install the manual programs in `manual-progs.csv`. It might be useful to open the file in the
   terminal and use `Control click` to open the URLs in the browser.
6. Generate ssh-keys to set up on GitHub, GitLab and what not.
   ```sh
   ssh-keygen -t rsa -b 2048 -C "email@example.com"
   ```
7. Follow the [zenbrowsing installation](https://github.com/florianperrenet/zenbrowsing) to
   experience distraction free browsing. Note: zenbrowsing is already located at
   `~/.opt/zenbrowsing`.

## Final notes

The `dotfiles` repo will be pulled using HTTPS to `/home/$USER/.local/share/dotfiles` and thus the
remote has to be changed to `git@github.com:yannickperrenet/dotfiles.git` in order to use SSH.
```sh
dfg remote rm origin \
    && dfg remote add origin git@github.com:yannickperrenet/dotfiles.git
```

In case you want to install proprietary NVIDIA drivers:
```sh
ubuntu-drivers devices
# Check what the recommended one is and install it
sudo apt-get install nvidia-driver-515
# Reboot PC and see what programs run on the GPU
nvidia-smi
```
