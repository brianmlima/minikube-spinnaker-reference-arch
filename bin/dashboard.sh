#!/usr/bin/env bash
################################################################################
################################################################################
# Access the kuberneties dashboard
################################################################################
################################################################################

################################################################################
## Resolves the directory this script is in. Tolerates symlinks.
SOURCE="${BASH_SOURCE[0]}" ;
while [[ -h "$SOURCE" ]] ; do TARGET="$(readlink "${SOURCE}")"; if [[ $SOURCE == /* ]]; then SOURCE="${TARGET}"; else DIR="$( dirname "${SOURCE}" )"; SOURCE="${DIR}/${TARGET}"; fi; done
BASE_DIR="$( cd -P "$( dirname "${SOURCE}" )" && pwd )" ;
PROJECT_HOME="$( cd -P "${BASE_DIR}/../" && pwd )"
################################################################################
################################################################################
source ${PROJECT_HOME}/bin/Functions.sh
source ${PROJECT_HOME}/bin/conf.sh
################################################################################

export POD_NAME=$(${BASE_DIR}/kubectl.sh get pods -n default -l "app=kubernetes-dashboard,release=kubernetes-dashboard" -o jsonpath="{.items[0].metadata.name}")
echo https://127.0.0.1:8443/
${BASE_DIR}/kubectl.sh -n default port-forward $POD_NAME 8443:8443
