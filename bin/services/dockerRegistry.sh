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
PROJECT_HOME="$(cd -P "${BASE_DIR}/../../" && pwd)"
WORK_HOME="${PROJECT_HOME}/work"
################################################################################
source ${PROJECT_HOME}/bin/Functions.sh
source ${PROJECT_HOME}/bin/conf.sh
########################################################################################################################

function start() {
  if [ "$(docker ps -q -f name=${DOCKER_REGISTRY_DOCKER_NAME})" ]; then
    info "A Docker Registry container is already running, I will not start another one."
  else
    docker run \
      -d \
      --rm \
      -p ${DOCKER_REGISTRY_PORT}:${DOCKER_REGISTRY_PORT} \
      --name "${DOCKER_REGISTRY_DOCKER_NAME}" registry:2
  fi
}

function stop() {
  docker stop ${DOCKER_REGISTRY_DOCKER_NAME}
  docker rm ${DOCKER_REGISTRY_DOCKER_NAME}
}

function minikubeUri() {
  if ${PROJECT_HOME}/bin/minikube.sh status >/dev/null; then
    local IP=$(${PROJECT_HOME}/bin/minikube.sh ssh grep host.minikube.internal /etc/hosts | cut -f1)
    echo "${IP}:${DOCKER_REGISTRY_PORT}"
  else
    exit -1
  fi
}

function containerIp() {
  echo "$(docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' ${DOCKER_REGISTRY_DOCKER_NAME}):${DOCKER_REGISTRY_PORT}"
}

function usage() {
  echo "stop            Stops the Docker Registry container."
  echo "start           Starts the Docker Registry container."
  echo "minikube-uri    Outputs the URI used to access the Docker Registry from inside the minikube cluster."
  echo "container-uri   Outputs the ip:port of the docker regestry container. Helps when pushing from the project host."
  echo "dump-variables  Dumps all the environment variables and script variables for this script."
  echo "-h | --help     Show this message."
}

########################################################################################################################
########################################################################################################################
# Parse args, exec or show help if no command is passed.

# parse commands and exec
for arg in ${1}; do
  case $arg in
  start)
    start
    exit 0
    ;;
  stop)
    stop
    exit 0
    ;;
  container-uri)
    containerIp
    exit 0
    ;;
  minikube-uri)
    minikubeUri
    exit 0
    ;;
  dump-variables)
    set -o posix
    set
    exit 0
    ;;
  -h | --help)
    usage
    exit 0
    ;;
  esac
done
usage
