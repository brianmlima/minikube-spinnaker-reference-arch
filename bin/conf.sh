#!/usr/bin/env bash

# DEPRECIATED: Refactor this variable name out and use WORK_HOME instead.
WORKING_DIR="${PROJECT_HOME}/work"

# The local directory where we do any work, store files, ect that are transient.
WORK_HOME="${PROJECT_HOME}/work"

KUBE_CONTEXT="minikube-istio"
HELM_HOME="${WORK_HOME}/helm"

ISTIO_REPO_REMOTE="https://gcsweb.istio.io/gcs/istio-release/releases/1.2.2/charts/"

ISTIO_REPO="istio.io"
ISTIO_NAMESPACE="istio-system"
#ISTIO_REPO

HAL_DEPLOY_TIMEOUT_MINS="30"

########################################################################################################################
# Minikube
# Minikube is the container technology this project uses. Generally we just assume it is working. On Mac we need to make
# sure we are able to share directories in the projects working directory.
########################################################################################################################
let MINIKUBE_MEMORY="(($(sysctl -n hw.memsize) / 1024) / 1024) / 2"
let MINIKUBE_CPUS="$(sysctl -n hw.ncpu) / 2"
MINIKUBE_DRIVER="hyperkit"

########################################################################################################################
# Docker
# Docker is the container technology this project uses. Generally we just assume it is working. On Mac we need to make
# sure we are able to share directories in the projects working directory.
########################################################################################################################
DOCKER_FILE_SHARING_CONFIG_FILE="${HOME}/Library/Group Containers/group.com.docker/settings.json"

########################################################################################################################
# Docker Registry
# In order to be self contained and show how to trigger a deployment on a docker registry push event we have to have our
# own local docker registry. We do this by starting a docker container that has a service that implements the docker
# registry api.
DOCKER_REGISTRY_PORT="5000"

DOCKER_REGISTRY_DOCKER_NAME="docker-registry"

########################################################################################################################
# MINO
# Halyard and some other components need an external storage engine, in production this would be AWS S3 however in the
# interest of keeping this refrence archetecture self contained we use a MINO docker instance that pretends to be S3 by
# implementing the same interface. This keeps the refrence archetecture self contained as it does not require a
# connection to an AWS account for testing and prototyping.
########################################################################################################################
MINIO_HOME="${WORK_HOME}/mino"
MINIO_DATA_HOME="${MINIO_HOME}/data"
MINIO_SECRET_KEY="KIAIOSFODNN7EXAMPLE"
MINIO_ACCESS_KEY="wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
MINIO_DOCKER_NAME="minio"
MINIO_HOST_PORT="9945"

########################################################################################################################
# Github
# This is the account that is configured in Spinnaker
########################################################################################################################
GITHUB_ACCOUNT_NAME="brianmlima"
GITHUB_TOKEN_FILE_NAME="github-api-token"
GITHUB_LOCAL_API_TOKEN_FILE="$(
  cd ~/
  pwd
)/.${GITHUB_TOKEN_FILE_NAME}"

########################################################################################################################
# OpenSSL
# We want to be able to stay as close to a production implementation in this project so we use certificates and dns to
# communicate with the cluster just like in production. In order to do this we need to be able to generate a certificate
# , get the local machine to trust the cert outright, and get the cluster to use the cert we generate to generate its
# own certificates for ingres. The foloowing configuration values help automate that process.
# @See https://tanzu.vmware.com/developer/blog/securely-connect-with-your-local-kubernetes-environment/
########################################################################################################################
# We need to know the home dir of the local openssl implemetation so we can
OPENSSL_HOME=$(openssl version -a | grep OPENSSLDIR | sed -e 's/^[^"]*"//g' -e 's/"//g')
