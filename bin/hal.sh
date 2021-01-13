#!/usr/bin/env bash
########################################################################################################################
########################################################################################################################
# Encapsulation of common tasks associated with using Halyard to manage and depoy spinnaker for a refrence architecture.
# Starts and uses a Halyard docker container in an effort to demonstrate use of Halyyard to manage and deploy Spinnaker
# on a kubernettes cluster. Try hal.sh -h for usage
# local docker HALYARD interface based on https://spinnaker.io/setup/install/halyard/#install-halyard-on-docker
########################################################################################################################
########################################################################################################################

########################################################################################################################
# COMMON SCRIPT HEADER #################################################################################################
# Resolves the directory this script is in. Tolerates symlinks. Provides a common ${PROJECT_HOME} for relative paths
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
# Import common functions and configuration.
source ${PROJECT_HOME}/bin/Functions.sh
source ${PROJECT_HOME}/bin/conf.sh
########################################################################################################################
########################################################################################################################

########################################################################################################################
# TEST LOCAL REQUIRED COMMANDS #########################################################################################
#Will fail the script if docker is not installed.
isCommandInstalled docker true
########################################################################################################################
########################################################################################################################

########################################################################################################################
# Project variables. ###################################################################################################
# The local directory where we do all our work for this project.
WORK_HOME="${PROJECT_HOME}/work"
# The local directory that is shared with the Halyard docker container. This keeps all the pertinant data for this
# project on the local machine for debugging and introspection.
HALYARD_HOME="${WORK_HOME}/halyard"
# Logging dir for the Halyard service on the Halyard docker container.
HALYARD_LOG="${HALYARD_HOME}/log"
# The name of the Halyard docker container.
HALYARD_DOCKER_NAME="halyard"
# Used to pass certs for the local minikube so Halyard can connect to the cluster.
HALYARD_MINIKUBE_HOME="${HALYARD_HOME}/minikube"
# The local machines minikube home, this is where we get certs and config from.
MINIKUBE_HOST_HOME="$(realpath ~/.minikube)"

########################################################################################################################
# Deplyment variables.

# The s3 bucket name spinnaker will use
HALYARD_S3_BUCKET_NAME="spinnaker"
# The version of spinnaker we want to deply
SPINNAKER_VERSION="1.24.1"
# The spinnaker namespace
SPINNAKER_NAMESPACE="spinnaker"

########################################################################################################################
# Used to expose Spinnaker spi and ui via LoadBalancers.

# spin-deck is the Spinnaker service that provides the Spinnake UI
SPIN_DECK_SERVICE_NAME="spin-deck"
SPIN_DECK_LOADBALANCER_NAME="${SPIN_DECK_SERVICE_NAME}-lb"
SPIN_DECK_PORT="30900"
# spin-gate is the Spinnaker service that provides the Spinnake API
SPIN_GATE_SERVICE_NAME="spin-gate"
SPIN_GATE_LOADBALANCER_NAME="${SPIN_GATE_SERVICE_NAME}-lb"
SPIN_GATE_PORT="30901"

########################################################################################################################
########################################################################################################################

########################################################################################################################
# FUNCTIONS ############################################################################################################

########################################################################################################################
# DOCKER: Runs a command on the Halyard docker container.
function runDockerCmd() {
  info "RUNNING DOCKER EXEC: ${1}"
  docker exec -it ${HALYARD_DOCKER_NAME} ${1}
  return ${?}
}

########################################################################################################################
# HALYARD: Configure the Halyard instances kubectl so it can connect to the cluster. If kubectl on the same machine as
# Halyard can connect to the cluster then telling Halyard what cluseter to deploy to is simple.
function configureContainersKubectl() {
  runDockerCmd "kubectl config set-cluster minikube --server=https://$(${PROJECT_HOME}/bin/minikube.sh ip):8443 --certificate-authority=/minikube/ca.crt"
  runDockerCmd "kubectl config set-credentials minikube --certificate-authority=/root/.minikube/ca.crt --client-key=/minikube/client.key --client-certificate=/minikube/client.crt"
  runDockerCmd "kubectl config set-context ${KUBE_CONTEXT} --cluster=minikube --user=minikube"
  runDockerCmd "kubectl config use-context ${KUBE_CONTEXT}"
  runDockerCmd "kubectl get pods --request-timeout 5s"
}

########################################################################################################################
# SPINNAKER: Tell Halyard what version of spinnaker we want to deploy.
function configureSpinnakerVersion() {
  runDockerCmd "hal config version edit --version ${SPINNAKER_VERSION}"
}

########################################################################################################################
# DOCKER: Block while the halyard service on the halyard continer is running.
function waitForHalDaemon() {
  until docker exec -it halyard hal --ready; do
    info "Waiting 2 more seconds for the Halyard daemon to start"
    sleep 2
  done
}

########################################################################################################################
# SPINNAKER: Spinnaker has the ability to trigger a deployment based on a github action. It is unclear if we are going to hook in
# to the push for deployment or watch something else but for experimentation sake we set up a link to github.
function configureGitHub() {
  # DOCKER_FIX: Spinnaker needs an api token so we copy a local token file to the halyard contianers local storage using  a docker
  # shared dir
  cp "${GITHUB_LOCAL_API_TOKEN_FILE}" "${HALYARD_MINIKUBE_HOME}/${GITHUB_TOKEN_FILE_NAME}.txt"
  # DOCKER_FIX: we copy the file on the halyard container so it is in a directory that the spinnaker user can write to as it makes
  # a backup file
  runDockerCmd "cp /home/spinnaker/.hal/minikube/${GITHUB_TOKEN_FILE_NAME}.txt /home/spinnaker/.hal/${GITHUB_TOKEN_FILE_NAME}"
  # SPINNAKER_CONFIG
  runDockerCmd "hal config artifact github enable"
  # SPINNAKER_CONFIG
  runDockerCmd "hal config artifact github account add ${GITHUB_ACCOUNT_NAME} --token-file /home/spinnaker/.hal/${GITHUB_TOKEN_FILE_NAME}"
  # SPINNAKER_DEPLOY
  runDockerCmd "hal deploy apply --wait-for-completion-timeout-minutes ${HAL_DEPLOY_TIMEOUT_MINS}"
}

########################################################################################################################
# Spinnaker requires an external storage service, it really likes s3. Because this project tries not to have any external
# dependencies we use a Minio on docker. Minio implements the s3 interface so as far as Spinnaker is concerned this is s3.
function configureHalyardStorage() {
  # Get the ip minikube uses to route to the local host.
  # Minio is a docker container on the local host so this is the ip the cluster uses to access the minio service.
  MINIO_IP=$(${PROJECT_HOME}/bin/minikube.sh ssh grep host.minikube.internal /etc/hosts | cut -f1)
  # Configure s3 storage for the pending spinnaker deployment. NOTE we echo in the secret key so it is not stored in
  # the halyard instances bash history.
  echo "${MINIO_SECRET_KEY}" | docker exec -i ${HALYARD_DOCKER_NAME} hal config storage s3 edit --access-key-id ${MINIO_ACCESS_KEY} --secret-access-key --region us-east-1 --path-style-access=true --bucket ${HALYARD_S3_BUCKET_NAME} --endpoint http://${MINIO_IP}:${MINIO_HOST_PORT}
  # Trigger the edit on halyard so the config is stored. NOTE: This might not be necessary.
  runDockerCmd "hal config storage edit --type s3"
}

########################################################################################################################
# SPINNAKER: Configure a docker regestry for spinnaker pipelines.
function configureDockerRegistry() {
  runDockerCmd "hal config provider docker-registry account add dockerhub --address index.docker.io --repositories library/nginx"
  runDockerCmd "hal config provider docker-registry enable"
}

########################################################################################################################
# SPINNAKER: Configure a provider so Spinnaker can connect
function configureHalyardProvider() {
  runDockerCmd "hal config provider kubernetes account add local-minikube --docker-registries dockerhub --context ${KUBE_CONTEXT}"
  runDockerCmd "hal config provider kubernetes enable"
  runDockerCmd "hal config deploy edit --type=distributed --account-name local-minikube"
}

########################################################################################################################
# Deletes an existing local ${HALYARD_HOME} abd sets a fresh one up so we ware sure our runs are absolutely from scratch.
function resetHalyardHome() {
  # Remove the hal home so we are sure we are working with a clean slate.
  rm -rf ${HALYARD_HOME}
  mkdir -p ${HALYARD_HOME}
  # Copy all the certs and config we need to connect the halyard container to the
  # local minikube to our working dir
  mkdir -p ${HALYARD_MINIKUBE_HOME}
  cp "${MINIKUBE_HOST_HOME}/client.crt" "${HALYARD_MINIKUBE_HOME}/client.crt"
  cp "${MINIKUBE_HOST_HOME}/client.key" "${HALYARD_MINIKUBE_HOME}/client.key"
  cp "${MINIKUBE_HOST_HOME}/ca.crt" "${HALYARD_MINIKUBE_HOME}/ca.crt"
  cp -r "${MINIKUBE_HOST_HOME}/certs" "${HALYARD_MINIKUBE_HOME}/"
}

########################################################################################################################
# Startes the Halyard docker conatiner.
function startHalyardContainer() {
  # Start the haluard container!
  docker run -p 8084:8084 -p 9000:9000 \
    --name "${HALYARD_DOCKER_NAME}" \
    -d \
    --rm \
    -v "${HALYARD_HOME}:/home/spinnaker/.hal" \
    -v "${HALYARD_MINIKUBE_HOME}:/minikube" \
    -it \
    us-docker.pkg.dev/spinnaker-community/docker/halyard:stable
  # Not sure if this works but try and wait for the container to start.
  until docker exec -it halyard "ls" >/dev/null; do
    info "Waiting 2 more seconds for the Halyard docker container to start"
    sleep 2
  done
}
########################################################################################################################
# Stop the Halyard container
function stopHalyardContainer() {
  docker stop ${HALYARD_DOCKER_NAME}
  if [ "$(docker ps -q -f name=${HALYARD_DOCKER_NAME})" ]; then
    if [ "$(docker ps -aq -f status=exited -f name=${HALYARD_DOCKER_NAME})" ]; then
      # cleanup
      docker rm ${HALYARD_DOCKER_NAME}
    fi
  fi
}

########################################################################################################################
# Sets up and deploys Spinnaker. Does not set up load balancers use hal.sh connect to do that.
function initializeSpinnaker() {
  if [ ! "$(docker ps -q -f name=${HALYARD_DOCKER_NAME})" ]; then
    if [ "$(docker ps -aq -f status=exited -f name=${HALYARD_DOCKER_NAME})" ]; then
      # cleanup
      docker rm ${HALYARD_DOCKER_NAME}
    fi
    ################################################################################
    # At this point we know the halyard container is not running so we can do the
    # initial setup and start the container.
    resetHalyardHome
    # start the container.
    startHalyardContainer
    # configure the halyard containers kubectl so it can access the cluster.
    configureContainersKubectl
    # Wait for the Halyard service to start on the container.
    waitForHalDaemon
    # HALYARD: Configure the Spinnaker version we want to deploy. @See ${SPINNAKER_VERSION}.
    configureSpinnakerVersion
    # HALYARD: Configure the persistant storage mechanism for the Spinnaker deployment
    configureHalyardStorage
    # HALYARD: Configure a docker registry for use in Spinnaker pipelines.
    configureDockerRegistry
    # HALYARD: Configure Spinnaker to be able to connect to the minikube kubernetes cluster.
    configureHalyardProvider

    ##################
    # Deploy twice because there is some bug that makes the first deploy fail for no good reason.
    runDockerCmd "hal deploy apply --wait-for-completion-timeout-minutes ${HAL_DEPLOY_TIMEOUT_MINS}"
    runDockerCmd "hal deploy apply --wait-for-completion-timeout-minutes ${HAL_DEPLOY_TIMEOUT_MINS}"
  fi
}

########################################################################################################################
# Sets up load balancers and base urls for the spinnaker API and UI. Also opens the ui in the systems default web
# browser.
function connect() {

  ############################################################
  # We need to create ingress points so the ui service (spin-deck) and the api service (spin-gate) is accessable from
  # outside the cluster.

  # KUBECTL: Create a load balancer ingress so we can access spin-deck from outside the cluster.
  kubectl expose svc ${SPIN_DECK_SERVICE_NAME} --port=${SPIN_DECK_PORT} --target-port=9000 -n ${SPINNAKER_NAMESPACE} --name=${SPIN_DECK_LOADBALANCER_NAME} --type=LoadBalancer
  # KUBECTL: Create a load balancer ingress so we can access spin-gate from outside the cluster.
  kubectl expose svc ${SPIN_GATE_SERVICE_NAME} --port=${SPIN_GATE_PORT} --target-port=8084 -n ${SPINNAKER_NAMESPACE} --name=${SPIN_GATE_LOADBALANCER_NAME} --type=LoadBalancer

  ############################################################
  # We need to set the load balancer base uris for the spinnaker deployment in the halyard config so the UI functions
  # correctly.

  # MINIKUBE: get the base uri for the spinnaker ui
  local UI_BASE_URL="$(${PROJECT_HOME}/bin/minikube.sh service -n ${SPINNAKER_NAMESPACE} --url ${SPIN_DECK_LOADBALANCER_NAME})"
  # MINIKUBE: get the base uri for the spinnaker api
  local API_BASE_URL="$(${PROJECT_HOME}/bin/minikube.sh service -n ${SPINNAKER_NAMESPACE} --url ${SPIN_GATE_LOADBALANCER_NAME})"

  # HALYARD: set the spinnaker ui base uri
  runDockerCmd "hal config security ui edit  --override-base-url ${UI_BASE_URL}"
  # HALYARD: set the spinnaker api base uri
  runDockerCmd "hal config security api edit --override-base-url ${API_BASE_URL}"
  # HALYARD: Deploy the changes to spinnaker using halyard
  runDockerCmd "hal deploy apply --wait-for-completion-timeout-minutes ${HAL_DEPLOY_TIMEOUT_MINS}"

  # LOGGING
  info "You can now reach Spinnaker UI at ${UI_BASE_URL} It may take a little time for the canary deployment to finish."
  # LOGGING
  info "You can now reach Spinnaker API at ${API_BASE_URL} It may take a little time for the canary deployment to finish."
  # LOGGING
  info "Opening ${UI_BASE_URL} in your default browser"
  # SYSTEM: Open the spinnaker ui on the local machine in the default browser.
  open "${UI_BASE_URL}"

}

function usage() {
  echo "stop            Stops the halyard container."
  echo "start           Starts the halyard container and configures it to connect to the minikube cluster."
  echo "spinnaker       Prepares and installs the default Spinnaker into the minikube cluster."
  echo "connect         Mounts ports 8084 and 9000 from the spinnaker install to the Halyard container."
  echo "github          Configure Github"
  echo "front-50-logs   Gets the logs of the front-50 service."
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
    if [ "$(docker ps -q -f name=${HALYARD_DOCKER_NAME})" ]; then
      error "A halyard container is already running, can not start another one."
    else
      resetHalyardHome
      startHalyardContainer
      configureContainersKubectl
      waitForHalDaemon
    fi
    exit 0
    ;;
  stop)
    stopHalyardContainer
    exit 0
    ;;
  spinnaker)
    initializeSpinnaker
    exit 0
    ;;
  connect)
    connect
    exit 0
    ;;
  front-50-logs)
    ${PROJECT_HOME}/bin/kubectl logs $(${PROJECT_HOME}/bin/kubectl get pods -n spinnaker | grep spin-front50 | awk '{print $1}') -n ${SPINNAKER_NAMESPACE} | less
    exit 0
    ;;
  github)
    configureGitHub
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
