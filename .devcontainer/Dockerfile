ARG BUILD_ON_IMAGE=glcr.b-data.ch/python/base
ARG PYTHON_VERSION=latest

FROM ${BUILD_ON_IMAGE}:${PYTHON_VERSION}

ARG DEBIAN_FRONTEND=noninteractive

## Update environment
ARG USE_ZSH_FOR_ROOT
ARG SET_LANG
ARG SET_TZ

ENV LANG=${SET_LANG:-$LANG} \
    TZ=${SET_TZ:-$TZ} \
    PARENT_IMAGE_BUILD_DATE=${BUILD_DATE}

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
  fi

## Pip: Install to the Python user install directory (1) or not (0)
ARG PIP_USER=1

ENV PIP_USER=${PIP_USER}

## Reset environment variable BUILD_DATE
ARG BUILD_START

ENV BUILD_DATE=${BUILD_START}
