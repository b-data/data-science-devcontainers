#!/usr/bin/env bash
# Copyright (c) 2023 b-data GmbH
# Distributed under the terms of the MIT License.

set -e

# Create R user library
mkdir -p "$(Rscript -e "cat(Sys.getenv('R_LIBS_USER'))")"

if [ -n "${RSTUDIO_VERSION}" ]; then
  # Set environment variables in Renviron.site
  exclude_vars="HOME LD_LIBRARY_PATH OLDPWD PATH PWD RSTUDIO_VERSION SHLVL"
  for var in $(compgen -e); do
    [[ ! $exclude_vars =~ $var ]] && echo "$var='${!var//\'/\'\\\'\'}'" \
      >> "$(R RHOME)/etc/Renviron.site"
  done
  RS_USD="$HOME/.config/rstudio"
  # Install RStudio settings if home directory is bind mounted
  mkdir -p "$RS_USD"
  if [[ ! -f "$RS_USD/rstudio-prefs.json" ]]; then
    cp -a /etc/skel/.config/rstudio/rstudio-prefs.json \
      "$RS_USD/rstudio-prefs.json"
  fi
  # Create user's working folder
  mkdir -p "$HOME/working"
fi

# Copy QGIS stuff from skeleton directory if home directory is bind mounted
if [ "$(id -un)" == "root" ]; then
  if [ "$(command -v qgis)" ] && [ ! -d /root/.local/share ]; then
    cp -R /etc/skel/.local/share /root/.local;
  fi

  # Copy plugin 'Processing Saga NextGen Provider'
  if [ "$(command -v qgis)" ]; then
    rm -rf /root/.local/share/QGIS/QGIS3/profiles/default/python/plugins/processing_saga_nextgen;
    cp -R /etc/skel/.local/share/QGIS/QGIS3/profiles/default/python/plugins/processing_saga_nextgen \
      /root/.local/share/QGIS/QGIS3/profiles/default/python/plugins/processing_saga_nextgen;
  fi

  # Copy plugin 'OrfeoToolbox Provider'
  if [ "$(command -v qgis)" ] && [ ! -d /root/.local/share/QGIS/QGIS3/profiles/default/python/plugins/orfeoToolbox_provider ]; then
    if [ -d /etc/skel/.local/share/QGIS/QGIS3/profiles/default/python/plugins/orfeoToolbox_provider ]; then
      cp -R /etc/skel/.local/share/QGIS/QGIS3/profiles/default/python/plugins/orfeoToolbox_provider \
        /root/.local/share/QGIS/QGIS3/profiles/default/python/plugins/orfeoToolbox_provider;
    fi
  fi
else
  if [ "$(command -v qgis)" ] && [ ! -d "$HOME/.local/share" ]; then
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

  # Copy plugin 'OrfeoToolbox Provider'
  if [ "$(command -v qgis)" ] && [ ! -d "$HOME/.local/share/QGIS/QGIS3/profiles/default/python/plugins/orfeoToolbox_provider" ]; then
    if [ -d /etc/skel/.local/share/QGIS/QGIS3/profiles/default/python/plugins/orfeoToolbox_provider ]; then
      sudo cp -R /etc/skel/.local/share/QGIS/QGIS3/profiles/default/python/plugins/orfeoToolbox_provider \
        "$HOME/.local/share/QGIS/QGIS3/profiles/default/python/plugins/orfeoToolbox_provider";
      sudo chown -R "$(id -u)":"$(id -g)" "$HOME/.local/share/QGIS/QGIS3/profiles/default/python/plugins/orfeoToolbox_provider";
    fi
  fi
fi
