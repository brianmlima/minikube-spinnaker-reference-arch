#!/usr/bin/env bash
################################################################################
################################################################################
# destroys a named minikube
################################################################################
################################################################################

################################################################################
## Resolves the directory this script is in. Tolerates symlinks.
SOURCE="${BASH_SOURCE[0]}"
while [[ -L "$SOURCE" ]]; do
  TARGET="$(readlink "${SOURCE}")"
  if [[ $SOURCE == /* ]]; then SOURCE="${TARGET}"; else
    DIR="$(dirname "${SOURCE}")"
    SOURCE="${DIR}/${TARGET}"
  fi
done
BASE_DIR="$(cd -P "$(dirname "${SOURCE}")" && pwd)"
PROJECT_HOME="$(cd -P "${BASE_DIR}/../" && pwd)"
################################################################################



${PROJECT_HOME}/bin/hal.sh stop
docker stop minio
${PROJECT_HOME}/bin/minikube.sh delete


rm -rf ${PROJECT_HOME}/work/*
