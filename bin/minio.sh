#!/usr/bin/env bash
################################################################################
################################################################################
# local docker Minio s3 implementation based on https://docs.min.io/docs/minio-docker-quickstart-guide.html
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

#Will fail the script if docker is not installed.
isCommandInstalled docker true

resetMinioHome() {
  # Remove the minio home so we are sure we are working with a clean slate.
  rm -rf ${MINIO_HOME}
  mkdir -p ${MINIO_HOME}
  mkdir -p ${MINIO_DATA_HOME}
}

startMinioContainer() {
  docker run -p ${MINIO_HOST_PORT}:9000 \
    --name ${MINIO_DOCKER_NAME} \
    -d \
    --rm \
    -v ${MINIO_DATA_HOME}:/data \
    -e "MINIO_ACCESS_KEY=${MINIO_ACCESS_KEY}" \
    -e "MINIO_SECRET_KEY=${MINIO_SECRET_KEY}" \
    minio/minio server /data
}

if [ ! "$(docker ps -q -f name=${MINIO_DOCKER_NAME})" ]; then
  if [ "$(docker ps -aq -f status=exited -f name=${MINIO_DOCKER_NAME})" ]; then
    # cleanup
    docker rm ${MINIO_DOCKER_NAME}
  fi

  ################################################################################
  # At this point we know the halyard container is not running so we can do the
  # initial setup and start the container.
  resetMinioHome
  startMinioContainer

else
  info "The minio docker container is already started. If you want to stop it run; docker stop ${MINIO_DOCKER_NAME}"

fi
