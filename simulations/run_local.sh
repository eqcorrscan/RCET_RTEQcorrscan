#!/bin/bash

# Local paths
DETECTION_HOSTPATH="${PWD}/detections"

# Container paths
BASE_PATH="/tmp/outputs"
DETECTION_DOCKERPATH="${BASE_PATH}/detections"

if [ ! -d $DETECTION_HOSTPATH ];then
  mkdir $DETECTION_HOSTPATH
  chmod og+wx $DETECTION_HOSTPATH
fi

IMAGE="rteq-simulator"
TAG="latest"

function usage(){
cat <<EOF
Usage: $0 [Options] 
Build or run docker $IMAGE

Optional Arguments:
    -h, --help              Show this message.
    -b, --build             Rebuild the image.
    -i, --interactive       Start the container with a bash prompt.
    --run                   Run event 2014p051675
    --image                 Provide alternative image name.
    --tag                   Provide alternative tag
EOF
}

# Processing command line options
while [ $# -gt 0 ]
do
    case "$1" in
        -b | --build) BUILD=true;;
        -i | --interactive) INTERACTIVE=true;;
        --run) RUN=true;shift;;
        --image) IMAGE="$2";shift;;
        --tag) TAG="$2";shift;;
        -h) usage; exit 0;;
        -*) usage; exit 1;;
esac
shift
done

if [ "${BUILD}" == "true" ]; then
  echo "Removing current version of ${IMAGE}:${TAG}"
  docker rmi "${IMAGE}:${TAG}"

  echo "Building ${IMAGE}:${TAG}"
  # Usually you should be able to re-use the old image, for changes to the rteqcorrscan or 
  # eqcorrscan repos we need to rebuild
  # docker build -t $IMAGE .
  docker build --no-cache -t $IMAGE:${TAG} .
fi

if [ "${RUN}" == "true" ]; then
  docker run \
    -m 16g --cpus=6 \
    -v $DETECTION_HOSTPATH:$DETECTION_DOCKERPATH \
    $IMAGE rteqcorrscan-simulation \
    --quake 2014p051675 \
    --config NZ_past_seq_config.yml \
    --db-duration 730 \
    --runtime 604800 \
    --client GEONET \
    --speed-up 10 \
    --working-dir $DETECTION_DOCKERPATH
fi

if [ "${INTERACTIVE}" == "true" ]; then
  docker run -it --rm \
      -m 16g --cpus=6 \
      -v $DETECTION_HOSTPATH:$DETECTION_DOCKERPATH \
      --entrypoint /bin/bash \
      ${IMAGE}:${TAG} 
  exit 0
fi

