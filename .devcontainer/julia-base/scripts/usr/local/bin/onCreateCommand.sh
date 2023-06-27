#!/usr/bin/env bash
# Copyright (c) 2023 b-data GmbH.
# Distributed under the terms of the MIT License.

set -e

mkdir -p "${HOME}/projects"
mkdir -p "${HOME}/.local/bin"

# Copy scripts from skeleton directory if home directory is bind mounted
if [ ! -f "${HOME}/.local/bin/dockerSystemPrune.sh" ]; then
  cp /etc/skel/.local/bin/dockerSystemPrune.sh "${HOME}/.local/bin";
fi
if [ ! -f "${HOME}/.local/bin/checkForUpdates.sh" ]; then
  cp /etc/skel/.local/bin/checkForUpdates.sh "${HOME}/.local/bin";
fi

# Copy Zsh-related files and folders from the untouched home directory
if [ "$(id -un)" == "root" ]; then
  if [ ! -d "${HOME}/.oh-my-zsh" ]; then
    cp -R /home/*/.oh-my-zsh "${HOME}";
  fi
  if [ ! -f "${HOME}/.zshrc" ]; then
    cp /home/*/.zshrc "${HOME}";
  fi
else
  if [ ! -d "${HOME}/.oh-my-zsh" ]; then
    sudo cp -R /root/.oh-my-zsh "${HOME}";
    sudo chown -R "$(id -u)":"$(id -g)" "${HOME}/.oh-my-zsh";
  fi
  if [ ! -f "${HOME}/.zshrc" ]; then
    sudo cp /root/.zshrc "${HOME}";
    sudo chown "$(id -u)":"$(id -g)" "${HOME}/.zshrc";
  fi
fi

# Set PATH so it includes user's private bin if it exists
if ! $(grep -q "user's private bin" $HOME/.zshrc); then
  echo -e "\n# set PATH so it includes user's private bin if it exists\nif [ -d \"\$HOME/bin\" ] && [[ \"\$PATH\" != *\"\$HOME/bin\"* ]] ; then\n    PATH=\"\$HOME/bin:\$PATH\"\nfi" >> ${HOME}/.zshrc;
  echo -e "\n# set PATH so it includes user's private bin if it exists\nif [ -d \"\$HOME/.local/bin\" ] && [[ \"\$PATH\" != *\"\$HOME/.local/bin\"* ]] ; then\n    PATH=\"\$HOME/.local/bin:\$PATH\"\nfi" >> ${HOME}/.zshrc;
fi

# Remove old .zcompdump files
rm -f ${HOME}/.zcompdump*
