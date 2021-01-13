#!/usr/bin/env bash
################################################################################
################################################################################
# Push local
################################################################################
################################################################################

################################################################################
## Resolves the directory this script is in. Tolerates symlinks.
SOURCE="${BASH_SOURCE[0]}" ;
while [[ -h "$SOURCE" ]] ; do TARGET="$(readlink "${SOURCE}")"; if [[ $SOURCE == /* ]]; then SOURCE="${TARGET}"; else DIR="$( dirname "${SOURCE}" )"; SOURCE="${DIR}/${TARGET}"; fi; done
BASE_DIR="$( cd -P "$( dirname "${SOURCE}" )" && pwd )" ;
PROJECT_HOME="$( cd -P "${BASE_DIR}/../" && pwd )"
################################################################################
source ${PROJECT_HOME}/bin/Functions.sh
source ${PROJECT_HOME}/bin/conf.sh
################################################################################

################################################################################
#Import conf.yml
eval $(parse_yaml ${PROJECT_HOME}/bin/conf.yml "conf_")
################################################################################

################################################################################
printHeader
################################################################################

isCommandInstalled minikube true
isCommandInstalled kubectl true
isCommandInstalled helm true

if [[ $(kubectl config current-context) != "${KUBE_CONTEXT}" ]]; then
    printMSG "${INFO} Setting the kubectl context to ${KUBE_CONTEXT}"
    kubectl config use-context "${KUBE_CONTEXT}"
fi
printMSG "${INFO} kubectl context is set to $(kubectl config current-context)"



HELM=${PROJECT_HOME}/bin/helm.sh
printMSG "${INFO}"
${HELM} repo remove ${ISTIO_REPO} | while read line ; do
    printMSG "${INFO} ${line}"
done

${HELM} repo add ${ISTIO_REPO} ${ISTIO_REPO_REMOTE} | while read line ; do
    printMSG "${INFO} ${line}"
done

${HELM} repo update | while read line ; do
    printMSG "${INFO} ${line}"
done


ISTIO_INIT_DEPLOYMENT_NAME="istio-init"
ISTIO_DEPLOYMENT_NAME="istio-init"
ISTIO_INIT


${HELM} install ${ISTIO_REPO}/istio-init --name ${ISTIO_INIT_DEPLOYMENT_NAME} --namespace ${ISTIO_NAMESPACE} | while read line ; do
    printMSG "${INFO} ${line}"
done

${HELM} install ${ISTIO_REPO}/istio --name ${ISTIO_DEPLOYMENT_NAME} --namespace ${ISTIO_NAMESPACE}| while read line ; do
    printMSG "${INFO} ${line}"
done


################################################################################
printFooter
################################################################################

#https://istio.io/charts
#./helm.sh repo remove istio.io ;
#./helm.sh repo add istio.io https://gcsweb.istio.io/gcs/istio-release/releases/1.2.2/charts/ ;
#./helm.sh repo remove update



#./helm.sh repo add istio.io https://gcsweb.istio.io/gcs/istio-prerelease/daily-build/release-1.2-latest-daily/charts/
#./helm.sh repo remove update
