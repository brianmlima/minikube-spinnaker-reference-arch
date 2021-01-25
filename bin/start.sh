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
MINIKUBE="minikube --profile ${KUBE_CONTEXT}"
CONF_HOME="${PROJECT_HOME}/conf"

################################################################################
printHeader
################################################################################

################################################################################
printMSG "${INFO} Checking for required local software"
isCommandInstalled curl true
isCommandInstalled minikube true
isCommandInstalled kubectl true
isCommandInstalled helm true
isCommandInstalled docker true
printMSG "${PASS} required local software installed"

################################################################################
MINIKUBE="${PROJECT_HOME}/bin/minikube.sh"
################################################################################

printMSG "${INFO} Giving minikube half the system resources for performance."
${MINIKUBE} config set memory ${MINIKUBE_MEMORY}
${MINIKUBE} config set cpus ${MINIKUBE_CPUS}
${MINIKUBE} config set vm-driver ${MINIKUBE_DRIVER}

printMSG "${INFO} Removing minikube ${KUBE_CONTEXT}"
${MINIKUBE} delete
printMSG "${INFO} Checking status of minikube ${KUBE_CONTEXT}"
${MINIKUBE} status
printMSG "${INFO} Starting minikube ${KUBE_CONTEXT}"
${MINIKUBE} start --kubernetes-version=1.18.14 --embed-certs

################################################################################
# Make sure the ingress plugin is installed so we can create loadbalancers like in a real cluster.
# Make sure the ingress-dns plugin is enabled so we can access services using *.minikube.test and use ssl.
# This is required to keep the project as close to a real implementation as possible and removes some problems you can
# encounter if you try to get some components to use insecure services.
# PER https://tanzu.vmware.com/developer/blog/securely-connect-with-your-local-kubernetes-environment/
info "Checking that ingress minikube plugin is enabled"
${MINIKUBE} addons enable ingress
info "Checking that ingress-dns minikube plugin is enabled"
${MINIKUBE} addons enable ingress-dns

printMSG "${INFO} Setting kubectl context to ${KUBE_CONTEXT}"
${PROJECT_HOME}/bin/kubectl.sh config use-context "${KUBE_CONTEXT}"

####################################################################################################################################
####################################################################################################################################
####################################################################################################################################
####################################################################################################################################
# Disabled, works but need to be moved into an istio command.
if false; then
  printMSG "${INFO} INSTALLING ISTIO per instructions found at https://istio.io/latest/docs/setup/install/helm/"

  ISTIO_WORK="${PROJECT_HOME}/work/istio-install"
  ISTIO_VERSION="1.8.1"
  ISTIO_LOCAL_CHARTS="${ISTIO_WORK}/istio-${ISTIO_VERSION}/manifests/charts"
  ISTIO_NAMESPACE="istio-system"

  printMSG "${INFO} Downloading ISTIO ${ISTIO_VERSION} to ${ISTIO_WORK}"

  if [[ ! -d "${ISTIO_WORK}" ]]; then
    mkdir -p "${ISTIO_WORK}"
  fi

  pushd "${ISTIO_WORK}"
  curl -L https://istio.io/downloadIstio | ISTIO_VERSION=${ISTIO_VERSION} TARGET_ARCH=x86_64 sh -
  popd

  printMSG "${INFO} KUBECTL Creating the ${ISTIO_NAMESPACE} namespace"
  ${PROJECT_HOME}/bin/kubectl.sh create namespace ${ISTIO_NAMESPACE}

  printMSG "${INFO} HELM Installing ISTIO base components chart"
  ${PROJECT_HOME}/bin/helm.sh install --namespace ${ISTIO_NAMESPACE} istio-base ${ISTIO_LOCAL_CHARTS}/base

  printMSG "${INFO} HELM Installing the ISTIO discovery chart which deploys the istiod service"
  ${PROJECT_HOME}/bin/helm.sh install --namespace ${ISTIO_NAMESPACE} istiod ${ISTIO_LOCAL_CHARTS}/istio-control/istio-discovery --set global.hub="docker.io/istio" --set global.tag="${ISTIO_VERSION}"
fi
####################################################################################################################################
####################################################################################################################################
####################################################################################################################################
####################################################################################################################################

#printMSG "${INFO} HELM Installing Istio Ingress Gateway chart which contains the ingress gateway components"
#${PROJECT_HOME}/bin/helm.sh install --namespace ${ISTIO_NAMESPACE} istio-ingress ${ISTIO_LOCAL_CHARTS}/gateways/istio-ingress --set global.hub="docker.io/istio" --set global.tag="${ISTIO_VERSION}"
#
#printMSG "${INFO} HELM Installing Istio Ingress Gateway chart which contains the ingress gateway components"
#${PROJECT_HOME}/bin/helm.sh install --namespace ${ISTIO_NAMESPACE} istio-egress ${ISTIO_LOCAL_CHARTS}/gateways/istio-egress --set global.hub="docker.io/istio" --set global.tag="${ISTIO_VERSION}"

#printMSG "${INFO} Adding ISTIO repository to HELM"
#helm repo add istio.io https://storage.googleapis.com/istio-release/releases/1.3.5/charts/
#
#printMSG "${INFO} Creating the istio-system namespace"
#kubectl create namespace istio-system
#
#printMSG "${INFO} Installing ISTIO base components using HELM"
#helm install -n istio-system istio-base istio.io/istio-init
#
#helm install --namespace istio-system istiod istio.io/istio --set global.hub="docker.io/istio" --set global.tag="1.3.5"

################################################################################

################################################################################
printFooter
################################################################################
