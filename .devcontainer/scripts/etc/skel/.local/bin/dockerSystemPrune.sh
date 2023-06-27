#!/usr/bin/env bash
# Copyright (c) 2023 b-data GmbH.
# Distributed under the terms of the MIT License.

set -e

# Codespace only: Silently remove all unused images and all build cache
if [ -n "$CODESPACES" ]; then docker system prune -f; fi
