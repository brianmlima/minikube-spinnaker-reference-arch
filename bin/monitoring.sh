#!/usr/bin/env bash
################################################################################
################################################################################
# Monitoring use and instalation utilities.
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
#helm --home ${HELM_HOME} --kube-context "${KUBE_CONTEXT}" ${@}

################################################################################
# Since we operate in a contained environment on minikube and home dirs for
# various commands we use the equivilant of local aliases so we dont have to
# repeat ourselves and we dont polute the environment with literal aliases.
function helm() {
  ${PROJECT_HOME}/bin/helm.sh ${@}
}

function kubectl() {
  ${PROJECT_HOME}/bin/kubectl.sh ${@}
}

function minikube() {
  ${PROJECT_HOME}/bin/minikube.sh ${@}
}

################################################################################

PROMETHEUS_PORT=9090
PROMETHEUS_SERVICE_NAME="prometheus-server"
PROMETHEUS_LOADBALANCER_NAME="${PROMETHEUS_SERVICE_NAME}-np"


KUBE_PROMETHEUS_STACK_CHART="prometheus-community/kube-prometheus-stack"
KUBE_PROMETHEUS_STACK_VERSION="12.10.6"





function installPrometheus() {
  helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
  helm repo add stable https://charts.helm.sh/stable
  helm repo update

  helm install kube-prometheus-stack ${KUBE_PROMETHEUS_STACK_CHART} --version=${KUBE_PROMETHEUS_STACK_VERSION}  --namespace=monitoring

  #helm install prometheus prometheus-community/kube-prometheus-stack
  #kubectl expose service ${PROMETHEUS_SERVICE_NAME} --type=LoadBalancer --port=${PROMETHEUS_PORT} --target-port=${PROMETHEUS_PORT} --name=${PROMETHEUS_LOADBALANCER_NAME}

}

function openPrometheus() {
  open $(minikube service ${PROMETHEUS_LOADBALANCER_NAME} --url)
}

GRAPHANA_PORT="3000"
GRAPHANA_SERVICE_NAME="grafana"
GRAPHANA_LOADBALANCER_NAME="${GRAPHANA_SERVICE_NAME}-lb"

function installGraphana() {
  helm repo add grafana https://grafana.github.io/helm-charts
  helm install grafana stable/grafana
  kubectl expose service ${GRAPHANA_SERVICE_NAME} --type=LoadBalancer --port=${GRAPHANA_PORT} --target-port=${GRAPHANA_PORT} --name=${GRAPHANA_LOADBALANCER_NAME}
}

function graphanaPassword() {
  kubectl get secret --namespace default ${GRAPHANA_SERVICE_NAME} -o jsonpath="{.data.admin-password}" | base64 --decode
  echo
}

function openGraphana() {
  open $(minikube service ${GRAPHANA_LOADBALANCER_NAME} --url)
}

usage() {
  echo "install-prometheus        Installs Prometheues into the local minikube."
  echo "openPrometheus            Uses the systems open command to open the prometheus ui in the default browser"
  echo "-h | --help     Show this message."
}

# parse commands and exec
for arg in ${1}; do
  case $arg in
  install-prometheus)
    installPrometheus
    exit 0
    ;;
  open-prometheus)
    openPrometheus
    exit 0
    ;;
  install-graphana)
    installGraphana
    exit 0
    ;;
  open-graphana)
    openGraphana
    exit 0
    ;;
  graphana-password)
    graphanaPassword
    exit 0
    ;;
  -h | --help)
    usage
    exit 0
    ;;
  esac
done
usage
