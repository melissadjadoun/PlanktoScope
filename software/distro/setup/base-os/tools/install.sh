#!/bin/bash -eux
# The base OS tools enable basic operation of the OS, and provide generalized mechanisms for
# bootstrapping further software (e.g. user applications) to be installed afterwards.

# Determine the base path for copied files
config_files_root=$(dirname $(realpath $BASH_SOURCE))

# Install some tools for a nicer command-line experience over ssh
# Note: we don't want to do an apt-get upgrade because then we'd have no way to ensure the same set
# of package versions for existing packages if we run the script at different times. Also, it causes
# some weirdness with the Docker installation (see note below in the "Install Docker" section).
sudo apt-get install -y vim byobu git curl

# Install some tools for dealing with captive portals
sudo apt-get install -y w3m lynx

# Install Docker
sudo install -m 0755 -d /etc/apt/keyrings
if [ ! -f /etc/apt/keyrings/docker.gpg ]; then
  curl -fsSL "https://download.docker.com/linux/debian/gpg" | \
    sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
fi
sudo chmod a+r /etc/apt/keyrings/docker.gpg
DISTRO_VERSION_CODENAME="$(. /etc/os-release && echo "$VERSION_CODENAME")"
echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
  "$DISTRO_VERSION_CODENAME" stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update -y # get the list of packages from the docker repo
# The following command may fail with a post-install error if the system installed kernel updates
# via apt upgrade but was not rebooted before installing docker-ce; however, even if this error
# is reported, docker will work after reboot.
# Refer to https://www.reddit.com/r/raspberry_pi/comments/zblky6/comment/iytpp4g/ for details.
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
sudo apt-get remove -y docker-buildx-plugin

# Allow running Docker commands without sudo. Before the next reboot, subsequent setup scripts will
# each need to call `newgrp docker` to take advantage of this
# (see https://docs.docker.com/engine/install/linux-postinstall/):
sudo usermod -aG docker $USER

# Install cockpit
sudo apt-get install -y --no-install-recommends cockpit
# TODO: after we switch to NetworkManager, add cockpit-networkmanager

# Install tool to generate machine names based on serial numbers
machinename_version="0.1.3"
arch="$(dpkg --print-architecture | sed -e 's/armhf/arm/' -e 's/aarch64/arm64/')"
curl -L "https://github.com/PlanktoScope/machine-name/releases/download/v$machinename_version/machine-name_${machinename_version}_linux_${arch}.tar.gz" \
  | sudo tar -xz -C /usr/bin/ machine-name
sudo mv /usr/bin/machine-name "/usr/bin/machine-name-${machinename_version}"
sudo ln -s "machine-name-${machinename_version}" /usr/bin/machine-name
# TODO: remove this by updating the Node-RED frontend and Python backend:
# Add a symlink at /var/lib/planktoscope/machine-name for backwards-compatibility with the Node-RED
# frontend and Python backend, which are not yet updated to check /run/machine-name instead:
sudo mkdir -p /var/lib/planktoscope
sudo ln -s /run/machine-name /var/lib/planktoscope/machine-name
