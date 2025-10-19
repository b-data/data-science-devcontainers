ARG BUILD_ON_IMAGE=glcr.b-data.ch/mojo/base
ARG MOJO_VERSION=25.6.0

ARG INSTALL_DEVTOOLS
ARG NODE_VERSION
ARG NV=${INSTALL_DEVTOOLS:+${NODE_VERSION:-22.19.0}}

ARG NSI_SFX=${NV:+/}${NV:-:none}${NV:+/debian}${NV:+:bullseye}

FROM ${BUILD_ON_IMAGE}:${MOJO_VERSION} as files

ARG BUILD_ON_IMAGE
ARG MOJO_VERSION

RUN mkdir /files

COPY conf/ipython /files
COPY conf/jupyterlab /files
COPY conf/shell /files
COPY mojo-base/conf/jupyterlab /files
COPY mojo-base/scripts /files
COPY scripts /files
COPY vsix /files

RUN if [ -n "${CUDA_VERSION}" ]; then \
    ## Use entrypoint of CUDA image
    mv /opt/nvidia/entrypoint.d /opt/nvidia/nvidia_entrypoint.sh \
      /files/usr/local/bin; \
    nlc=$(wc -l < /files/usr/local/bin/nvidia_entrypoint.sh); \
    sed -i "$((nlc-4)),$nlc s/^/# /" \
      /files/usr/local/bin/nvidia_entrypoint.sh; \
  fi \
  && if [ "${MOJO_VERSION}" != "nightly" ]; then \
    if dpkg --compare-versions "${MOJO_VERSION}" lt "25.4.0"; then \
      ## Fix path for the Mojo LSP server
      sed -i "s|/usr/local|/opt/modular|g" \
        /files/usr/local/etc/jupyter/jupyter_server_config.d/mojo-lsp-server.json; \
    fi \
  fi \
  ## Ensure file modes are correct
  && find /files -type d -exec chmod 755 {} \; \
  && find /files -type f -exec chmod 644 {} \; \
  && find /files/etc/skel/.local/bin -type f -exec chmod 755 {} \; \
  && find /files/usr/local/bin -type f -exec chmod 755 {} \; \
  && cp -r /files/etc/skel/. /files/root \
  && bash -c 'rm -rf /files/root/{.bashrc,.profile}' \
  && chmod 700 /files/root

FROM ghcr.io/hadolint/hadolint:latest as hsi

FROM docker.io/koalaman/shellcheck:stable as sci

FROM ${BUILD_ON_IMAGE}:${MOJO_VERSION} as mojo

ARG DEBIAN_FRONTEND=noninteractive

ARG BUILD_ON_IMAGE
ARG UNMINIMIZE
ARG JUPYTERLAB_VERSION=4.4.9

ENV PIXI_NO_PATH_UPDATE=1

ENV PARENT_IMAGE=${BUILD_ON_IMAGE}:${MOJO_VERSION} \
    JUPYTERLAB_VERSION=${JUPYTERLAB_VERSION} \
    PARENT_IMAGE_BUILD_DATE=${BUILD_DATE}

## Unminimise if the system has been minimised
RUN if [ "$(command -v unminimize)" ] && [ -n "$UNMINIMIZE" ]; then \
    sed -i "s/apt-get upgrade/#apt-get upgrade/g" "$(which unminimize)"; \
    yes | unminimize; \
    sed -i "s/#apt-get upgrade/apt-get upgrade/g" "$(which unminimize)"; \
  fi

RUN dpkgArch="$(dpkg --print-architecture)" \
  ## Add user vscode to group users
  && sed -i- 's/users:x:100:/users:x:100:vscode/g' /etc/group \
  ## Ensure that common CA certificates
  ## and OpenSSL libraries are up to date
  && apt-get update \
  && apt-get -y install --no-install-recommends --only-upgrade \
    ca-certificates \
    openssl \
## Install Python related stuff
  ## Install JupyterLab
  && pip install --no-cache-dir \
    jupyter-server-proxy \
    jupyterlab=="$JUPYTERLAB_VERSION" \
    jupyterlab-git \
    jupyterlab-lsp \
    notebook \
    nbclassic \
    nbconvert \
    "python-lsp-server[all]" \
  && if ! echo "$BUILD_ON_IMAGE" | grep -q "base"; then \
    pip install --no-cache-dir \
      ipympl \
      ipywidgets \
      widgetsnbextension; \
      ## Install facets
      cd /tmp; \
      git clone https://github.com/PAIR-code/facets.git; \
      jupyter nbclassic-extension install facets/facets-dist/ --sys-prefix; \
  fi \
  ## Clean up
  && rm -rf /tmp/* \
    /root/.cache \
## Dev container only
  ## Create backup of root directory
  && cp -a /root /var/backups \
  ## Clean up
  && rm -rf /var/lib/apt/lists/*

## Devtools, Docker
FROM glcr.b-data.ch/nodejs/nsi${NSI_SFX} as nsi

FROM mojo

ARG DEBIAN_FRONTEND=noninteractive

ARG NV
ARG INSTALL_DOCKER_CLI

ENV NODE_VERSION=${NV}

  ## Prevent Corepack showing the URL when it needs to download software
ENV COREPACK_ENABLE_DOWNLOAD_PROMPT=0

  ## Install Node.js...
COPY --from=nsi /usr/local /usr/local

RUN if [ -n "$NV" ]; then \
    ## and other requirements
    apt-get update; \
    apt-get install -y --no-install-recommends \
      bats \
      libkrb5-dev \
      libsecret-1-dev \
      libx11-dev \
      libxkbfile-dev \
      libxt6 \
      quilt \
      rsync; \
    if [ -n "$PYTHON_VERSION" ]; then \
      ## make some useful symlinks that are expected to exist
      ## ("/usr/bin/python" and friends)
      for src in pydoc3 python3; do \
        dst="$(echo "$src" | tr -d 3)"; \
        [ -s "/usr/bin/$src" ]; \
        [ ! -e "/usr/bin/$dst" ]; \
        ln -svT "$src" "/usr/bin/$dst"; \
      done; \
    fi; \
    ## Clean up Node.js installation
    bash -c 'rm -f /usr/local/bin/{docker-entrypoint.sh,yarn*}'; \
    bash -c 'mv /usr/local/{CHANGELOG.md,LICENSE,README.md} \
      /usr/local/share/doc/node'; \
    ## Enable corepack (Yarn, pnpm)
    corepack enable; \
    ## Install nFPM
    echo 'deb [trusted=yes] https://repo.goreleaser.com/apt/ /' \
      | tee /etc/apt/sources.list.d/goreleaser.list; \
    apt-get update; \
    apt-get install -y --no-install-recommends nfpm; \
    ## Clean up
    rm -rf /tmp/*; \
    rm -rf /var/lib/apt/lists/* \
      /root/.config \
      /root/.local; \
  fi \
  && if [ -n "$INSTALL_DOCKER_CLI" ]; then \
    ## Install Docker CLI and plugins
    dpkgArch="$(dpkg --print-architecture)"; \
    . /etc/os-release; \
    mkdir -p /etc/apt/keyrings; \
    chmod 0755 /etc/apt/keyrings; \
    pgpKey="$(curl -fsSL "https://download.docker.com/linux/$ID/gpg")"; \
    echo "$pgpKey" | gpg --dearmor -o /etc/apt/keyrings/docker.gpg; \
    echo "deb [arch=$dpkgArch signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/$ID $VERSION_CODENAME stable" | \
      tee /etc/apt/sources.list.d/docker.list > /dev/null; \
    apt-get update; \
    apt-get -y install --no-install-recommends \
      docker-ce-cli \
      docker-buildx-plugin \
      docker-compose-plugin; \
    ln -s /usr/libexec/docker/cli-plugins/docker-compose \
      /usr/local/bin/docker-compose; \
    ## Clean up
    rm -rf /var/lib/apt/lists/* \
      /root/.config; \
  fi

## Update environment
ARG USE_ZSH_FOR_ROOT
ARG LANG
ARG TZ

ARG LANG_OVERRIDE=${LANG}
ARG TZ_OVERRIDE=${TZ}

ENV LANG=${LANG_OVERRIDE:-$LANG} \
    TZ=${TZ_OVERRIDE:-$TZ}

  ## Change root's shell to ZSH
RUN if [ -n "$USE_ZSH_FOR_ROOT" ]; then \
    chsh -s /bin/zsh; \
  fi \
  ## Info about timezone
  && echo "TZ is set to $TZ" \
  ## Add/Update locale if requested
  && if [ "$LANG" != "en_US.UTF-8" ]; then \
    sed -i "s/# $LANG/$LANG/g" /etc/locale.gen; \
    locale-gen; \
  fi \
  && update-locale --reset LANG="$LANG" \
  ## Info about locale
  && echo "LANG is set to $LANG"

## Use Jupyter Server Proxy for TensorBoard
ENV TENSORBOARD_PROXY_URL=/proxy/%PORT%/

## Unset environment variable BUILD_DATE
ENV BUILD_DATE=

## Copy files as late as possible to avoid cache busting
COPY --from=files /files /

## Copy binaries as late as possible to avoid cache busting
## Install Haskell Dockerfile Linter
COPY --from=hsi /bin/hadolint /usr/local/bin
## Install ShellCheck
COPY --from=sci --chown=root:root /bin/shellcheck /usr/local/bin
