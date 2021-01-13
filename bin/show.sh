#!/usr/bin/env bash
################################################################################
################################################################################
# Reports on the cluster in general using get and describe
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
source ${PROJECT_HOME}/bin/Functions.sh
source ${PROJECT_HOME}/bin/conf.sh
################################################################################

################################################################################
printHeader
################################################################################

isCommandInstalled minikube true
isCommandInstalled kubectl true

info "Getting All Namespaces"
./bin/kubectl.sh get namespaces -o name | while read namespaceLine; do
  nameSpace=$(echo "${namespaceLine}" | sed -e 's/.*\///g')
  info "Reporting on Namespace ${nameSpace}"
  ./bin/kubectl.sh describe "${namespaceLine}"
  info "Reporting on Services in Namespace ${nameSpace}"
  ./bin/kubectl.sh get services -n "${nameSpace}"
done

################################################################################
printFooter
################################################################################
