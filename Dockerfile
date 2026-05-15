# syntax=docker/dockerfile:1

FROM alpine AS fetchstage

COPY checksums /

RUN \
  echo "**** Installing packages ****" && \
  apk add --no-cache \
    coreutils curl && \
  echo "**** Fetching Miniconda installer ****" && \
  if [ $(uname -m) = "x86_64" ]; then \
    curl -o \
      /miniconda-installer.sh -L \
      "https://repo.anaconda.com/miniconda/Miniconda3-py313_26.3.2-2-Linux-x86_64.sh" && \
    sha256sum -c /miniconda-installer-x86_64.sh.sha256; \
  elif [ $(uname -m) = "aarch64" ]; then \
    curl -o \
      /miniconda-installer.sh -L \
      "https://repo.anaconda.com/miniconda/Miniconda3-py313_26.3.2-2-Linux-aarch64.sh" && \
    sha256sum -c /miniconda-installer-aarch64.sh.sha256; \
  fi

FROM frolvlad/alpine-glibc AS buildstage

COPY --from=fetchstage /miniconda-installer.sh /miniconda-installer.sh

RUN \
  echo "**** Installing packages ****" && \
  apk add --no-cache \
    bash cmake make g++ && \
  echo "**** Installing Miniconda ****" && \
  bash /miniconda-installer.sh -b -p /opt/miniconda3 && \
  echo "**** Installing LLVM ****" && \
  /opt/miniconda3/bin/conda tos accept --override-channels \
    --channel https://repo.anaconda.com/pkgs/main \
    --channel https://repo.anaconda.com/pkgs/r && \
  /opt/miniconda3/bin/conda install -c numba -q -y llvmdev

FROM scratch AS combinestage

COPY --from=buildstage /opt/miniconda3/ /opt/miniconda3/

# copy local files
COPY root/ /

FROM scratch

LABEL maintainer="nolsto"

# Final image needs to consist of a single layer.
# https://github.com/linuxserver/docker-mods/issues/753#issuecomment-1696678516
COPY --from=combinestage / /
