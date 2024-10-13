#!/usr/bin/env bash
# Copyright (c) 2023 b-data GmbH.
# Distributed under the terms of the MIT License.

set -e

# Create user's private bin
mkdir -p "$HOME/.local/bin"

# Create user's projects and workspaces folder
mkdir -p "$HOME/projects"
mkdir -p "$HOME/workspaces"

# Copy scripts from skeleton directory if home directory is bind mounted
if [ ! -f "$HOME/.local/bin/dockerSystemPrune.sh" ]; then
  if [ -f /etc/skel/.local/bin/dockerSystemPrune.sh ]; then
    cp /etc/skel/.local/bin/dockerSystemPrune.sh "$HOME/.local/bin";
  fi
fi
if [ ! -f "$HOME/.local/bin/checkForUpdates.sh" ]; then
  if [ -f /etc/skel/.local/bin/checkForUpdates.sh ]; then
    cp /etc/skel/.local/bin/checkForUpdates.sh "$HOME/.local/bin";
  fi
fi

# Copy Bash-related files from root's backup directory
if [ "$(id -un)" == "root" ]; then
  if [ ! -f /root/.bashrc ]; then
    cp /var/backups/root/.bashrc /root;
  fi
  if [ ! -f /root/.profile ]; then
    cp /var/backups/root/.profile /root;
  fi
fi

# Copy Zsh-related files and folders from the untouched home directory
if [ "$(id -un)" == "root" ]; then
  if [ ! -d /root/.oh-my-zsh ]; then
    cp -R /home/*/.oh-my-zsh /root;
  fi
  if [ ! -f /root/.zshrc ]; then
    cp /home/*/.zshrc /root;
  fi
else
  if [ ! -d "$HOME/.oh-my-zsh" ]; then
    sudo cp -R /root/.oh-my-zsh "$HOME";
    sudo chown -R "$(id -u)":"$(id -g)" "$HOME/.oh-my-zsh";
  fi
  if [ ! -f "$HOME/.zshrc" ]; then
    sudo cp /root/.zshrc "$HOME";
    sudo chown "$(id -u)":"$(id -g)" "$HOME/.zshrc";
  fi
fi

if ! grep -q "user's private bin" "$HOME/.bashrc"; then
  # If existent, prepend the user's private bin to PATH
  cat "/var/tmp/snippets/rc.sh" >> "$HOME/.bashrc"
fi
if ! grep -q "user's private bin" "$HOME/.zshrc"; then
  if [ "$(command -v mojo)" ]; then
    # Append the magic bin dir to PATH
    curl -ssL https://magic.modular.com | grep '^MODULAR_HOME\|^BIN_DIR' \
      > /tmp/magicenv
    sed -i 's/\$HOME/\\$HOME/g' /tmp/magicenv
    . /tmp/magicenv
    echo -e "\nif [[ \"\$PATH\" != *\"${BIN_DIR}\"* ]] ; then\n    PATH=\"\$PATH:${BIN_DIR}\"\nfi" >> "$HOME/.zshrc"
    rm /tmp/magicenv
  fi
  # If existent, prepend the user's private bin to PATH
  cat "/var/tmp/snippets/rc.sh" >> "$HOME/.zshrc"
fi

# Enable Oh My Zsh plugins
sed -i "s/plugins=(git)/plugins=(docker docker-compose git git-lfs pip screen tmux vscode)/g" \
  "$HOME/.zshrc"

# Remove old .zcompdump files
rm -f "$HOME"/.zcompdump*

# Fix for older versions
if [ -d /opt/TinyTeX ]; then
  if [ "$(stat -c %G /opt/TinyTeX)" != "users" ]; then
    sudo chown -R :users /opt/TinyTeX
  fi
fi
