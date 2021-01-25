#!/usr/bin/env bash
########################################################################################################################
########################################################################################################################
# Checks the local system for commands and configuration necessary to run this project

########################################################################################################################
########################################################################################################################

########################################################################################################################
# Standard header found in all scripts.
################################################################################
# Resolves the directory this script is in. Tolerates symlinks.
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
WORK_HOME="${PROJECT_HOME}/work"
################################################################################
source ${PROJECT_HOME}/bin/Functions.sh
source ${PROJECT_HOME}/bin/conf.sh
########################################################################################################################

################################################################################
printMSG "${INFO} Checking for required local software"
isCommandInstalled curl true
isCommandInstalled minikube true
isCommandInstalled kubectl true
isCommandInstalled helm true
isCommandInstalled docker true
printMSG "${PASS} required local software installed"

function checkFileSharing() {
  local lookFor="$(echo "${WORK_HOME}" | sed -e 's/\//\\\\\//g')"
  local successMsg="${PASS} Confirmed: ${WORK_HOME} can be used as a shared directory with docker containers"
  local failMsg="${FAIL} ${WORK_HOME} must be configured with the docker host to be shared. You can configure shared paths from Docker -> Preferences... -> Resources -> File Sharing. and restart docker for changes to take effect."
  # LOG
  printMSG "${INFO} Checking ${WORK_HOME} is allowed to be shared with docker containers."
  # CHECK to make sure the required work directory is in the docker config file for sharing.
  if grep -q "${lookFor}" "${DOCKER_FILE_SHARING_CONFIG_FILE}"; then
    printMSG "${successMsg}"
  else
    printMSG "${failMsg}"
    exit -1
  fi
}

function findOpenSSLConfigFile(){



}




########################################################################################################################
printHeader
########################################################################################################################

checkFileSharing

########################################################################################################################
printFooter
########################################################################################################################
