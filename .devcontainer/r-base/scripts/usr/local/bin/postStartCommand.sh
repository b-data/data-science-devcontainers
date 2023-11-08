#!/usr/bin/env bash
# Copyright (c) 2023 b-data GmbH.
# Distributed under the terms of the MIT License.

set -e

# Copy QGIS stuff from skeleton directory if home directory is bind mounted
if [ "$(id -un)" == "root" ]; then
  if [ ! -d /root/.local/share ] && [ "$(command -v qgis)" ]; then
    cp -R /etc/skel/.local/share /root/.local;
  fi
  # Copy plugin 'Processing Saga NextGen Provider'
  if [ "$(command -v qgis)" ]; then
    rm -rf /root/.local/share/QGIS/QGIS3/profiles/default/python/plugins/processing_saga_nextgen;
    cp -R /etc/skel/.local/share/QGIS/QGIS3/profiles/default/python/plugins/processing_saga_nextgen \
      /root/.local/share/QGIS/QGIS3/profiles/default/python/plugins/processing_saga_nextgen;
  fi
else
  if [ ! -d "$HOME/.local/share" ] && [ "$(command -v qgis)" ]; then
    sudo cp -R /etc/skel/.local/share "$HOME/.local";
    sudo chown -R "$(id -u)":"$(id -g)" "$HOME/.local/share";
  fi
  # Copy plugin 'Processing Saga NextGen Provider'
  if [ "$(command -v qgis)" ]; then
    sudo rm -rf "$HOME/.local/share/QGIS/QGIS3/profiles/default/python/plugins/processing_saga_nextgen";
    sudo cp -R /etc/skel/.local/share/QGIS/QGIS3/profiles/default/python/plugins/processing_saga_nextgen \
      "$HOME/.local/share/QGIS/QGIS3/profiles/default/python/plugins/processing_saga_nextgen";
    sudo chown -R "$(id -u)":"$(id -g)" "$HOME/.local/share/QGIS/QGIS3/profiles/default/python/plugins/processing_saga_nextgen";
  fi
fi

# Create R user package library
RLU="$(Rscript -e "cat(Sys.getenv('R_LIBS_USER'))")"
mkdir -p "$RLU"
