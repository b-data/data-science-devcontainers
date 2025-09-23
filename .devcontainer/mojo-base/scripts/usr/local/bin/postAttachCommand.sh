#!/usr/bin/env bash
# Copyright (c) 2024 b-data GmbH
# Distributed under the terms of the MIT License.

set -e

# MAX SDK: Evaluate and set version
if [ -n "$CODESPACES" ]; then
  extDataDir=$HOME/.vscode-remote/data/User/globalStorage/modular-mojotools.vscode-mojo
else
  extDataDir=$HOME/.vscode-server/data/User/globalStorage/modular-mojotools.vscode-mojo
fi

while :
  do
  extDirs=( "$HOME"/.vscode-*/extensions/modular-mojotools.vscode-mojo* )
  [ "${#extDirs[@]}" -ge 2 ] && exit 1
  if [ -d "${extDirs[0]}" ]; then
    sdkVersion=$(jq -r '.sdkVersion' "${extDirs[0]}/package.json")
    if [ "$sdkVersion" = "null" ]; then
      sdkVersion=$(jq -r '.version' "${extDirs[0]}/package.json")
    fi
    break
  else
    sleep 1
  fi
done

if [ "${MOJO_VERSION}" = "nightly" ]; then
  # MAX SDK: Create symlink to /usr/local
  mkdir -p "$extDataDir/magic-data-home/envs"
  ln -snf /usr/local "$extDataDir/magic-data-home/envs/max"
  ln -snf /usr/local "$extDataDir/magic-data-home/envs/mojo"
  mkdir -p "$extDataDir/versionDone/$sdkVersion"
else
  if dpkg --compare-versions "${MOJO_VERSION}" ge "25.4.0"; then
    # MAX SDK: Create symlink to /usr/local
    mkdir -p "$extDataDir/magic-data-home/envs"
    ln -snf /usr/local "$extDataDir/magic-data-home/envs/max"
    ln -snf /usr/local "$extDataDir/magic-data-home/envs/mojo"
    mkdir -p "$extDataDir/versionDone/$sdkVersion"
  else
    # MAX SDK: Create symlink to /opt/modular
    mkdir -p "$extDataDir/magic-data-home/envs"
    ln -snf /opt/modular "$extDataDir/magic-data-home/envs/max"
    mkdir -p "$extDataDir/versionDone/$sdkVersion"
  fi
fi
