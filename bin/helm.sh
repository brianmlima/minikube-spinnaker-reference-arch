#!/usr/bin/env bash
################################################################################
################################################################################
# starts a named minikube
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
################################################################################
source ${PROJECT_HOME}/bin/Functions.sh
source ${PROJECT_HOME}/bin/conf.sh
################################################################################
export HELM_HOME=${PROJECT_HOME}/work/helm
################################################################################
isCommandInstalled helm true true

HELM_CACHE_HOME="${HELM_HOME}/cache"
HELM_CONFIG_HOME="${HELM_HOME}/config"
HELM_DATA_HOME="${HELM_HOME}/data"

function makedir() {
  if [[ ! -d ${@} ]]; then
    command mkdir -p ${@}
  fi
}

function checkHelmHome() {
  makedir ${HELM_HOME}
  makedir ${HELM_CACHE_HOME}
  makedir ${HELM_CONFIG_HOME}
  makedir ${HELM_DATA_HOME}
}

checkHelmHome

  helm --kube-context "${KUBE_CONTEXT}" ${@}
