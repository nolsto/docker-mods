# syntax=docker/dockerfile:1

FROM alpine AS fetchstage

RUN mkdir -p /root-layer

COPY root/ /root-layer/

RUN \
  echo "**** install packages ****" && \
  apk add --no-cache \
    coreutils curl && \
  echo "**** fetch Miniconda installer ****" && \
  if [ $(uname -m) = "x86_64" ]; then \
    curl -o \
      /root-layer/miniconda-installer.sh -L \
      "https://repo.anaconda.com/miniconda/Miniconda3-py313_26.3.2-2-Linux-x86_64.sh" && \
    sha256sum -c /root-layer/miniconda-installer-x86_64.sh.sha256; \
  elif [ $(uname -m) = "aarch64" ]; then \
    curl -o \
      /root-layer/miniconda-installer.sh -L \
      "https://repo.anaconda.com/miniconda/Miniconda3-py313_26.3.2-2-Linux-aarch64.sh" && \
    sha256sum -c /root-layer/miniconda-installer-aarch64.sh.sha256; \
  fi

FROM frolvlad/alpine-glibc AS buildstage

COPY --from=fetchstage /root-layer/ /root-layer/

RUN \
  echo "**** install packages ****" && \
  apk add --no-cache \
    bash cmake make g++ && \
  echo "**** install Miniconda ****" && \
  bash /root-layer/miniconda-installer.sh -b -p /root-layer/miniconda

FROM scratch

LABEL maintainer="nolsto"

COPY --from=buildstage /root-layer/miniconda /miniconda
