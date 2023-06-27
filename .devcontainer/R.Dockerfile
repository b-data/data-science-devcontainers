ARG BUILD_ON_IMAGE=glcr.b-data.ch/r/base
ARG R_VERSION=4.3.1

ARG INSTALL_DEVTOOLS
ARG NODE_VERSION
ARG NV=${INSTALL_DEVTOOLS:+${NODE_VERSION:-16.20.1}}

FROM ${BUILD_ON_IMAGE}:${R_VERSION} as files

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN mkdir /files

COPY conf/ipython /files
COPY conf/jupyterlab /files
COPY r-base/scripts /files
COPY scripts /files

## Ensure file modes are correct when using CI
## Otherwise set to 777 in the target image
RUN find /files -type d -exec chmod 755 {} \; \
  && find /files -type f -exec chmod 644 {} \; \
  && find /files/etc/skel/.local/bin -type f -exec chmod 755 {} \; \
  && find /files/usr/local/bin -type f -exec chmod 755 {} \; \
  && cp -r /files/etc/skel/. /files/root \
  && chmod 700 /files/root

FROM ${BUILD_ON_IMAGE}:${R_VERSION} as r

ARG DEBIAN_FRONTEND=noninteractive

ARG BUILD_ON_IMAGE
ARG UNMINIMIZE
ARG JUPYTERLAB_VERSION=3.6.4

ENV PARENT_IMAGE=${BUILD_ON_IMAGE}:${R_VERSION} \
    JUPYTERLAB_VERSION=${JUPYTERLAB_VERSION} \
    PARENT_IMAGE_BUILD_DATE=${BUILD_DATE}

SHELL ["/bin/sh", "-c"]

## Unminimise if the system has been minimised
RUN if [ $(command -v unminimize) -a ! -z "$UNMINIMIZE" ]; then \
    yes | unminimize; \
  fi

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

## Install Python related stuff
  ## Install JupyterLab
RUN pip install \
    jupyterlab==${JUPYTERLAB_VERSION} \
    jupyterlab-git \
    jupyterlab-lsp \
    notebook \
    nbconvert \
    python-lsp-server[all] \
## Install R related stuff
  ## Install the R kernel for Jupyter and languageserver
  && install2.r --error --deps TRUE --skipinstalled -n $((`nproc`+1)) \
    IRkernel \
    languageserver \
  && Rscript -e "IRkernel::installspec(user = FALSE, displayname = paste('R', Sys.getenv('R_VERSION')))" \
  ## IRkernel: Enable 'image/svg+xml' instead of 'image/png' for plot display
  ## IRkernel: Enable 'application/pdf' for PDF conversion
  && echo "options(jupyter.plot_mimetypes = c('text/plain', 'image/svg+xml', 'application/pdf'))" \
    >> $(R RHOME)/etc/Rprofile.site \
  ## IRkernel: Include user's private bin in PATH
  && echo "if (dir.exists(file.path(Sys.getenv('HOME'), 'bin')) &&" \
    >> $(R RHOME)/etc/Rprofile.site \
  && echo '  !grepl(file.path(Sys.getenv('\''HOME'\''), '\''bin'\''), Sys.getenv('\''PATH'\''))) {' \
    >> $(R RHOME)/etc/Rprofile.site \
  && echo "  Sys.setenv(PATH = paste(file.path(Sys.getenv('HOME'), 'bin'), Sys.getenv('PATH')," \
    >> $(R RHOME)/etc/Rprofile.site \
  && echo "    sep = .Platform\$path.sep))}" \
    >> $(R RHOME)/etc/Rprofile.site \
  && echo "if (dir.exists(file.path(Sys.getenv('HOME'), '.local', 'bin')) &&" \
    >> $(R RHOME)/etc/Rprofile.site \
  && echo '  !grepl(file.path(Sys.getenv('\''HOME'\''), '\''.local'\'', '\''bin'\''), Sys.getenv('\''PATH'\''))) {' \
    >> $(R RHOME)/etc/Rprofile.site \
  && echo "  Sys.setenv(PATH = paste(file.path(Sys.getenv('HOME'), '.local', 'bin'), Sys.getenv('PATH')," \
    >> $(R RHOME)/etc/Rprofile.site \
  && echo "    sep = .Platform\$path.sep))}" \
    >> $(R RHOME)/etc/Rprofile.site \
  ## REditorSupport.r: Disable help panel and revert to old behaviour
  && echo "options(vsc.helpPanel = FALSE)" >> $(R RHOME)/etc/Rprofile.site \
  ## Clean up
  && rm -rf /tmp/* \
    /root/.cache \
    /root/.ipython \
    /root/.local/share/jupyter \
## Dev Container only
  ## Create folders in root directory
  && mkdir -p /root/.local/bin \
  && mkdir -p /root/projects \
  ## Create folders in skeleton directory
  && mkdir -p /etc/skel/.local/bin \
  && mkdir -p /etc/skel/projects \
  && if [ $(command -v qgis) ]; then \
    cp -a /root/.local/share /etc/skel/.local; \
  fi \
  ## Create R user package library
  && RLU=$(Rscript -e "cat(Sys.getenv('R_LIBS_USER'))") \
  && mkdir -p ${RLU}

## Devtools
FROM glcr.b-data.ch/nodejs/nsi${NV:+/}${NV:-:none}${NV:+/debian}${NV:+:bullseye} as nsi

FROM r

ARG DEBIAN_FRONTEND=noninteractive

ARG NV

ENV NODE_VERSION=${NV}

  ## Install Node.js...
COPY --from=nsi /usr/local /usr/local

RUN if [ ! -z "$NODE_VERSION" ]; then \
    ## and other requirements
    apt-get update; \
    apt-get install -y --no-install-recommends \
      bats \
      libsecret-1-dev \
      libx11-dev \
      libxkbfile-dev \
      libxt6 \
      quilt \
      rsync; \
    if [ ! -z "$PYTHON_VERSION" ]; then \
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
  fi

## Update environment
ARG USE_ZSH_FOR_ROOT
ARG SET_LANG
ARG SET_TZ

ENV LANG=${SET_LANG:-$LANG} \
    TZ=${SET_TZ:-$TZ}

  ## Change root's shell to ZSH
RUN if [ ! -z "$USE_ZSH_FOR_ROOT" ]; then \
    chsh -s /bin/zsh; \
  fi \
  ## Update timezone if needed
  && if [ "$TZ" != "Etc/UTC" ]; then \
    echo "Setting TZ to $TZ"; \
    ln -snf /usr/share/zoneinfo/$TZ /etc/localtime \
      && echo $TZ > /etc/timezone; \
  fi \
  ## Add/Update locale if needed
  && if [ "$LANG" != "en_US.UTF-8" ]; then \
    sed -i "s/# $LANG/$LANG/g" /etc/locale.gen; \
    locale-gen; \
    echo "Setting LANG to $LANG"; \
    update-locale --reset LANG=$LANG; \
  fi

## Pip: Install to the Python user install directory (1) or not (0)
ARG PIP_USER=1

ENV PIP_USER=${PIP_USER}

## Copy files as late as possible to avoid cache busting
COPY --from=files /files /

## Reset environment variable BUILD_DATE
ARG BUILD_START

ENV BUILD_DATE=${BUILD_START}
