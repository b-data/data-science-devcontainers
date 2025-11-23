ARG BUILD_ON_IMAGE=glcr.b-data.ch/r/base
ARG R_VERSION=4.5.2
ARG RSTUDIO_VERSION

ARG INSTALL_DEVTOOLS
ARG NODE_VERSION
ARG NV=${INSTALL_DEVTOOLS:+${NODE_VERSION:-22.20.0}}

ARG NSI_SFX=${NV:+/}${NV:-:none}${NV:+/debian}${NV:+:bullseye}

FROM ${BUILD_ON_IMAGE}:${R_VERSION} as files

ARG RSTUDIO_VERSION

RUN mkdir /files

COPY conf/ipython /files
COPY conf/shell /files
COPY r-base/conf/jupyterlab /files
COPY r-base/conf/rstudio /files
COPY r-base/scripts /files
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
  && if [ -z "${RSTUDIO_VERSION}" ]; then \
    rm -rf /files/etc/rstudio \
      /files/etc/skel/.config; \
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

FROM ${BUILD_ON_IMAGE}:${R_VERSION} AS base

FROM ${BUILD_ON_IMAGE}:${R_VERSION} AS base-rstudio

ARG RSTUDIO_VERSION

ENV RSTUDIO_VERSION=${RSTUDIO_VERSION}

## Connect to RStudio via unix socket
ENV JUPYTER_RSESSION_PROXY_USE_SOCKET=1

FROM base${RSTUDIO_VERSION:+-rstudio} as r

ARG DEBIAN_FRONTEND=noninteractive

ENV PARENT_IMAGE_CRAN=${CRAN}

ARG BUILD_ON_IMAGE
ARG CRAN
ARG NCPUS
ARG R_BINARY_PACKAGES
ARG UNMINIMIZE
ARG JUPYTERLAB_VERSION=4.5.0

ARG CRAN_OVERRIDE=${CRAN}

ENV PARENT_IMAGE=${BUILD_ON_IMAGE}:${R_VERSION} \
    CRAN=${CRAN_OVERRIDE:-$CRAN} \
    R_BINARY_PACKAGES=${R_BINARY_PACKAGES} \
    JUPYTERLAB_VERSION=${JUPYTERLAB_VERSION} \
    PARENT_IMAGE_BUILD_DATE=${BUILD_DATE}

## Unminimise if the system has been minimised
RUN if [ "$(command -v unminimize)" ] && [ -n "$UNMINIMIZE" ]; then \
    sed -i "s/apt-get upgrade/#apt-get upgrade/g" "$(which unminimize)"; \
    yes | unminimize; \
    sed -i "s/#apt-get upgrade/apt-get upgrade/g" "$(which unminimize)"; \
  fi

## Install RStudio
RUN if [ -n "${RSTUDIO_VERSION}" ]; then \
    dpkgArch="$(dpkg --print-architecture)"; \
    . /etc/os-release; \
    apt-get update; \
    ## Install lsb-release
    if [ "$ID" = "debian" ]; then \
      dpkg --compare-versions "$VERSION_ID" lt "12"; \
      condDebian=$?; \
    fi; \
    if [ "$ID" = "ubuntu" ]; then \
      dpkg --compare-versions "$VERSION_ID" lt "23.04"; \
      condUbuntu=$?; \
    fi; \
    if [ "$condDebian" = "0" ]; then \
      curl -sL \
        http://mirrors.kernel.org/debian/pool/main/l/lsb-release-minimal/lsb-release_12.0-1_all.deb \
        -o lsb-release.deb; \
      dpkg -i lsb-release.deb; \
      rm lsb-release.deb; \
    elif [ "$condUbuntu" = "0" ]; then \
      curl -sL \
        http://mirrors.kernel.org/ubuntu/pool/main/l/lsb-release-minimal/lsb-release_12.0-2_all.deb \
        -o lsb-release.deb; \
      dpkg -i lsb-release.deb; \
      rm lsb-release.deb; \
    else \
      apt-get -y install --no-install-recommends lsb-release; \
    fi; \
    ## Map Ubuntu codename
    if [ "$ID" = "debian" ]; then \
      case "$VERSION_CODENAME" in \
        bullseye) UBUNTU_CODENAME="focal" ;; \
        bookworm) UBUNTU_CODENAME="jammy" ;; \
        trixie) UBUNTU_CODENAME="jammy" ;; \
        *) echo "error: Debian $VERSION unsupported"; exit 1 ;; \
      esac; \
    fi; \
    if [ "$ID" = "ubuntu" ]; then \
      case "$VERSION_CODENAME" in \
        noble) UBUNTU_CODENAME="jammy" ;; \
        *) echo "error: Ubuntu $VERSION unsupported"; exit 1 ;; \
      esac; \
    fi; \
    ## Install RStudio
    ## https://github.com/rstudio/rstudio/blob/main/package/linux/CMakeLists.txt
    apt-get -y install --no-install-recommends \
      libapparmor1 \
      libpq5 \
      libsqlite3-0 \
      libssl-dev; \
    rm -rf /var/lib/apt/lists/*; \
    DOWNLOAD_FILE=rstudio-server-$(echo $RSTUDIO_VERSION | tr + -)-$dpkgArch.deb; \
    wget --progress=dot:mega \
      "https://download2.rstudio.org/server/$UBUNTU_CODENAME/$dpkgArch/$DOWNLOAD_FILE" || \
      wget --progress=dot:mega \
      "https://s3.amazonaws.com/rstudio-ide-build/server/$UBUNTU_CODENAME/$dpkgArch/$DOWNLOAD_FILE"; \
    dpkg -i "$DOWNLOAD_FILE"; \
    rm "$DOWNLOAD_FILE"; \
    ## Enable rstudio-server and rserver system-wide
    ln -fs /usr/lib/rstudio-server/bin/rstudio-server /usr/local/bin; \
    ln -fs /usr/lib/rstudio-server/bin/rserver /usr/local/bin; \
    ## Check for quarto redundancy
    if [ -d /opt/quarto ]; then \
      ## Remove RStudio quarto
      rm -rf /usr/lib/rstudio-server/bin/quarto; \
      ## Link to system quarto
      ln -s /opt/quarto /usr/lib/rstudio-server/bin/quarto; \
    fi \
  fi

RUN dpkgArch="$(dpkg --print-architecture)" \
  ## Add user vscode to group users
  && sed -i- 's/users:x:100:/users:x:100:vscode/g' /etc/group \
  ## Ensure that common CA certificates
  ## and OpenSSL libraries are up to date
  && apt-get update \
  && apt-get -y install --only-upgrade \
    ca-certificates \
    openssl \
## Install CUDA related stuff
  && if [ -n "${CUDA_VERSION}" ]; then \
    ## Install command-line tools and nvcc
    CUDA_VERSION_MAJ_MIN_DASH=$(echo ${CUDA_VERSION%.*} | tr '.' '-'); \
    apt-get -y install --no-install-recommends \
      cuda-command-line-tools-${CUDA_VERSION_MAJ_MIN_DASH}=${NV_CUDA_LIB_VERSION} \
      cuda-nvcc-${CUDA_VERSION_MAJ_MIN_DASH}; \
  fi \
## Install Python related stuff
  ## Install JupyterLab
  && pip install --no-cache-dir \
    jupyter-server-proxy \
    jupyterlab=="$JUPYTERLAB_VERSION" \
    jupyterlab-git \
    jupyterlab-lsp \
    notebook \
    nbconvert \
    nbclassic \
    "python-lsp-server[all]" \
    ${RSTUDIO_VERSION:+jupyter-rsession-proxy} \
## Install R related stuff
  && CRAN_ORIG=$(sed -n "s/.*CRAN='\(.*\)'),.*$/\1/p" "$(R RHOME)/etc/Rprofile.site") \
  && CRAN_ORIG_P3M=$(echo "$CRAN_ORIG" | sed 's/packagemanager.posit.co/p3m.dev/g') \
  ## Update CRAN mirror
  && if [ "$CRAN" != "$CRAN_ORIG" ]; then \
    sed -i "s|$CRAN_ORIG|$CRAN|g" "$(R RHOME)/etc/Rprofile.site"; \
  fi \
  ## Use binary packages
  && if [ "$R_BINARY_PACKAGES" = "1" ] || [ "$R_BINARY_PACKAGES" = "yes" ]; then \
    if [ "$CRAN" = "$CRAN_ORIG" ] || [ "$CRAN" = "$CRAN_ORIG_P3M" ]; then \
      . /etc/os-release; \
      ## Set options repos and HTTPUserAgent in Rprofile.site
      sed -i "s|cran|cran/__linux__/$VERSION_CODENAME|g" \
        "$(R RHOME)/etc/Rprofile.site"; \
      echo '# https://docs.rstudio.com/rspm/admin/serving-binaries/#binaries-r-configuration-linux' \
        >> "$(R RHOME)/etc/Rprofile.site"; \
      echo 'options(HTTPUserAgent = sprintf("R/%s R (%s)", getRversion(), paste(getRversion(), R.version["platform"], R.version["arch"], R.version["os"])))' \
        >> "$(R RHOME)/etc/Rprofile.site"; \
    fi \
  fi \
  ## Install pak
  && pkgType="$(Rscript -e 'cat(.Platform$pkgType)')" \
  && os="$(Rscript -e 'cat(R.Version()$os)')" \
  && arch="$(Rscript -e 'cat(R.Version()$arch)')" \
  && install2.r -r "https://r-lib.github.io/p/pak/stable/$pkgType/$os/$arch" -e \
    pak \
  ## Install the R kernel for Jupyter, languageserver and decor
  && install2.r -s -d TRUE -n "${NCPUS:-$(($(nproc)+1))}" -e \
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
  ## Change ownership and permission of $(R RHOME)/etc/*.site
  && chmod go+w "$(R RHOME)/etc" "$(R RHOME)/etc/"*.site \
  ## Clean up
  && rm -rf /tmp/* \
    /root/.cache \
    /root/.ipython \
    /root/.local/share/jupyter \
## Dev container only
  ## Create content in skeleton directory
  && if [ "$(command -v qgis)" ]; then \
    mkdir -p /etc/skel/.local; \
    cp -a /root/.local/share /etc/skel/.local; \
  fi \
  ## Create backup of root directory
  && cp -a /root /var/backups \
  ## Clean up
  && rm -rf /var/lib/apt/lists/*

ARG VIRTUALGL_VERSION=3.1.3

## Install VirtualGL
RUN if [ "$(command -v qgis)" ]; then \
    dpkgArch="$(dpkg --print-architecture)"; \
    curl -fsSL "https://github.com/VirtualGL/virtualgl/releases/download/${VIRTUALGL_VERSION}/virtualgl_${VIRTUALGL_VERSION}_${dpkgArch}.deb" -o virtualgl.deb; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
      mesa-utils \
      ./virtualgl.deb; \
    ## Install misc Vulkan utilities
    apt-get install -y --no-install-recommends \
      mesa-vulkan-drivers \
      vulkan-tools; \
    ## Make libraries available for preload
    chmod u+s /usr/lib/libvglfaker.so; \
    chmod u+s /usr/lib/libdlfaker.so; \
    ## Configure EGL manually (fallback)
    mkdir -p /usr/share/glvnd/egl_vendor.d/; \
    echo "{\n\
    \"file_format_version\" : \"1.0.0\",\n\
    \"ICD\" : {\n\
        \"library_path\" : \"libEGL_nvidia.so.0\"\n\
    }\n\
}" > /usr/share/glvnd/egl_vendor.d/10_nvidia.json; \
    ## Configure Vulkan manually (fallback)
    VULKAN_API_VERSION=$(dpkg -s libvulkan1 | grep -oP 'Version: [0-9|\.]+' | grep -oP '[0-9]+(\.[0-9]+)(\.[0-9]+)'); \
    mkdir -p /etc/vulkan/icd.d/; \
    echo "{\n\
    \"file_format_version\" : \"1.0.0\",\n\
    \"ICD\": {\n\
        \"library_path\": \"libGLX_nvidia.so.0\",\n\
        \"api_version\" : \"${VULKAN_API_VERSION}\"\n\
    }\n\
}" > /etc/vulkan/icd.d/nvidia_icd.json; \
  ## Clean up
  rm -rf /var/lib/apt/lists/* \
    virtualgl.deb; \
  fi

## Devtools, Docker
FROM glcr.b-data.ch/nodejs/nsi${NSI_SFX} as nsi

FROM r

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
