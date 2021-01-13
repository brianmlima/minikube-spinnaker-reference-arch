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
