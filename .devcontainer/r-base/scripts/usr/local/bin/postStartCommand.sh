#!/usr/bin/env bash
# Copyright (c) 2023 b-data GmbH.
# Distributed under the terms of the MIT License.

set -e

# Copy QGIS stuff from skeleton directory if home directory is bind mounted
if [ "$(id -un)" == "root" ]; then
  if [ ! -d /root/.local/share ] && [ $(command -v qgis) ]; then
    cp -R /etc/skel/.local/share /root/.local;
  fi
else
  if [ ! -d "${HOME}/.local/share" ] && [ $(command -v qgis) ]; then
    sudo cp -R /etc/skel/.local/share "${HOME}/.local";
    sudo chown -R "$(id -u)":"$(id -g)" "${HOME}/.local/share";
  fi
fi

# Create R user package library
RLU=$(Rscript -e "cat(Sys.getenv('R_LIBS_USER'))")
mkdir -p ${RLU}
