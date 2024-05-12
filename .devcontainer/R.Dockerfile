ARG BUILD_ON_IMAGE=glcr.b-data.ch/r/base
ARG R_VERSION=4.4.0

ARG INSTALL_DEVTOOLS
ARG NODE_VERSION
ARG NV=${INSTALL_DEVTOOLS:+${NODE_VERSION:-18.19.1}}

ARG NSI_SFX=${NV:+/}${NV:-:none}${NV:+/debian}${NV:+:bullseye}

FROM ${BUILD_ON_IMAGE}:${R_VERSION} as files

RUN mkdir /files

COPY conf/ipython /files
COPY conf/shell /files
COPY r-base/conf/jupyterlab /files
COPY r-base/scripts /files
COPY scripts /files

RUN if [ -n "${CUDA_VERSION}" ]; then \
    mv /opt/nvidia/entrypoint.d /opt/nvidia/nvidia_entrypoint.sh \
      /files/usr/local/bin; \
    nlc=$(wc -l < /files/usr/local/bin/nvidia_entrypoint.sh); \
    sed -i "$((nlc-4)),$nlc s/^/# /" \
      /files/usr/local/bin/nvidia_entrypoint.sh; \
  fi \
  ## Ensure file modes are correct
  && find /files -type d -exec chmod 755 {} \; \
  && find /files -type f -exec chmod 644 {} \; \
  && find /files/etc/skel/.local/bin -type f -exec chmod 755 {} \; \
  && find /files/usr/local/bin -type f -exec chmod 755 {} \; \
  && cp -r /files/etc/skel/. /files/root \
  && bash -c 'rm -rf /files/root/{.bashrc,.profile}' \
  && chmod 700 /files/root

FROM docker.io/koalaman/shellcheck:stable as sci

FROM ${BUILD_ON_IMAGE}:${R_VERSION} as r

ARG DEBIAN_FRONTEND=noninteractive

ENV PARENT_IMAGE_CRAN=${CRAN}

ARG BUILD_ON_IMAGE
ARG CRAN
ARG UNMINIMIZE
ARG JUPYTERLAB_VERSION=4.2.0

ARG CRAN_OVERRIDE=${CRAN}

ENV PARENT_IMAGE=${BUILD_ON_IMAGE}:${R_VERSION} \
    CRAN=${CRAN_OVERRIDE:-$CRAN} \
    JUPYTERLAB_VERSION=${JUPYTERLAB_VERSION} \
    PARENT_IMAGE_BUILD_DATE=${BUILD_DATE}

## Unminimise if the system has been minimised
RUN if [ "$(command -v unminimize)" ] && [ -n "$UNMINIMIZE" ]; then \
    sed -i "s/apt-get upgrade/#apt-get upgrade/g" "$(which unminimize)"; \
    yes | unminimize; \
    sed -i "s/#apt-get upgrade/apt-get upgrade/g" "$(which unminimize)"; \
  fi

RUN dpkgArch="$(dpkg --print-architecture)" \
  ## Ensure that common CA certificates
  ## and OpenSSL libraries are up to date
  && apt-get update \
  && apt-get -y install --only-upgrade \
    ca-certificates \
    openssl \
## Install Python related stuff
  ## Install JupyterLab
  && pip install --no-cache-dir \
    jupyterlab=="$JUPYTERLAB_VERSION" \
    jupyterlab-git \
    jupyterlab-lsp \
    notebook \
    nbconvert \
    nbclassic \
    "python-lsp-server[all]" \
## Install R related stuff
  ## Install pak
  && pkgType="$(Rscript -e 'cat(.Platform$pkgType)')" \
  && os="$(Rscript -e 'cat(R.Version()$os)')" \
  && arch="$(Rscript -e 'cat(R.Version()$arch)')" \
  && install2.r -r "https://r-lib.github.io/p/pak/stable/$pkgType/$os/$arch" -e \
    pak \
  ## Install the R kernel for Jupyter, languageserver and decor
  && install2.r -s -d TRUE -n "$(($(nproc)+1))" -e \
    IRkernel \
    languageserver \
    decor \
  && Rscript -e "IRkernel::installspec(user = FALSE, displayname = paste('R', Sys.getenv('R_VERSION')))" \
  ## IRkernel: Enable 'image/svg+xml' instead of 'image/png' for plot display
  ## IRkernel: Enable 'application/pdf' for PDF conversion
  && echo "options(jupyter.plot_mimetypes = c('text/plain', 'image/svg+xml', 'application/pdf'))" \
    >> "$(R RHOME)/etc/Rprofile.site" \
  ## IRkernel: Include user's private bin in PATH
  && echo "if (dir.exists(file.path(Sys.getenv('HOME'), 'bin')) &&" \
    >> "$(R RHOME)/etc/Rprofile.site" \
  && echo '  !grepl(file.path(Sys.getenv('\''HOME'\''), '\''bin'\''), Sys.getenv('\''PATH'\''))) {' \
    >> "$(R RHOME)/etc/Rprofile.site" \
  && echo "  Sys.setenv(PATH = paste(file.path(Sys.getenv('HOME'), 'bin'), Sys.getenv('PATH')," \
    >> "$(R RHOME)/etc/Rprofile.site" \
  && echo "    sep = .Platform\$path.sep))}" \
    >> "$(R RHOME)/etc/Rprofile.site" \
  && echo "if (dir.exists(file.path(Sys.getenv('HOME'), '.local', 'bin')) &&" \
    >> "$(R RHOME)/etc/Rprofile.site" \
  && echo '  !grepl(file.path(Sys.getenv('\''HOME'\''), '\''.local'\'', '\''bin'\''), Sys.getenv('\''PATH'\''))) {' \
    >> "$(R RHOME)/etc/Rprofile.site" \
  && echo "  Sys.setenv(PATH = paste(file.path(Sys.getenv('HOME'), '.local', 'bin'), Sys.getenv('PATH')," \
    >> "$(R RHOME)/etc/Rprofile.site" \
  && echo "    sep = .Platform\$path.sep))}" \
    >> "$(R RHOME)/etc/Rprofile.site" \
  ## REditorSupport.r: Disable help panel and revert to old behaviour
  && echo "options(vsc.helpPanel = FALSE)" >> "$(R RHOME)/etc/Rprofile.site" \
  ## Clean up
  && rm -rf /tmp/* \
    /root/.cache \
    /root/.ipython \
    /root/.local/share/jupyter \
## Dev Container only
  ## Install hadolint
  && case "$dpkgArch" in \
    amd64) tarArch="x86_64" ;; \
    arm64) tarArch="arm64" ;; \
    *) echo "error: Architecture $dpkgArch unsupported"; exit 1 ;; \
  esac \
  && apiResponse="$(curl -sSL \
    https://api.github.com/repos/hadolint/hadolint/releases/latest)" \
  && downloadUrl="$(echo "$apiResponse" | grep -e \
    "browser_download_url.*Linux-$tarArch\"" | cut -d : -f 2,3 | tr -d \")" \
  && echo "$downloadUrl" | xargs curl -sSLo /usr/local/bin/hadolint \
  && chmod 755 /usr/local/bin/hadolint \
  ## Create content in skeleton directory
  && if [ "$(command -v qgis)" ]; then \
    mkdir -p /etc/skel/.local; \
    cp -a /root/.local/share /etc/skel/.local; \
  fi \
  ## Create backup of root directory
  && cp -a /root /var/backups \
  ## Clean up
  && rm -rf /var/lib/apt/lists/*

## Devtools, Docker
FROM glcr.b-data.ch/nodejs/nsi${NSI_SFX} as nsi

FROM r

ARG DEBIAN_FRONTEND=noninteractive

ARG NV
ARG INSTALL_DOCKER_CLI

ENV NODE_VERSION=${NV}

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
      /root/.config; \
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
      docker-compose-plugin \
      "$(test "$dpkgArch" = "amd64" && echo docker-scan-plugin)"; \
    ln -s /usr/libexec/docker/cli-plugins/docker-compose \
      /usr/local/bin/docker-compose; \
    ## Clean up
    rm -rf /var/lib/apt/lists/* \
      /root/.config; \
  fi

## Update environment
ARG USE_ZSH_FOR_ROOT
ARG SET_LANG
ARG SET_TZ

ENV LANG=${SET_LANG:-$LANG} \
    TZ=${SET_TZ:-$TZ}

  ## Change root's shell to ZSH
RUN if [ -n "$USE_ZSH_FOR_ROOT" ]; then \
    chsh -s /bin/zsh; \
  fi \
  ## Update timezone if needed
  && if [ "$TZ" != "Etc/UTC" ]; then \
    echo "Setting TZ to $TZ"; \
    ln -snf "/usr/share/zoneinfo/$TZ" /etc/localtime \
      && echo "$TZ" > /etc/timezone; \
  fi \
  ## Add/Update locale if needed
  && if [ "$LANG" != "en_US.UTF-8" ]; then \
    sed -i "s/# $LANG/$LANG/g" /etc/locale.gen; \
    locale-gen; \
    echo "Setting LANG to $LANG"; \
    update-locale --reset LANG="$LANG"; \
  fi \
  ## Update CRAN
  && sed -i "s|$PARENT_IMAGE_CRAN|$CRAN|g" "$(R RHOME)/etc/Rprofile.site"

## Copy files as late as possible to avoid cache busting
COPY --from=files /files /

## Copy shellcheck as late as possible to avoid cache busting
COPY --from=sci --chown=root:root /bin/shellcheck /usr/local/bin

## Unset environment variable BUILD_DATE
ENV BUILD_DATE=
