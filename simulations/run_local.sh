#!/bin/bash

# Local paths
DETECTION_HOSTPATH="$(pwd -P)/detections"

# Container paths
BASE_PATH="/tmp/outputs"
DETECTION_DOCKERPATH="${BASE_PATH}/detections"

if [ ! -d $DETECTION_HOSTPATH ];then
  mkdir $DETECTION_HOSTPATH
  chmod og+wx $DETECTION_HOSTPATH
fi

echo "Working in $DETECTION_HOSTPATH"

# Defaults that can be overwritten by the user through cmd line args
IMAGE="rteq-simulator"
TAG="latest"

# Defaults for simulation
EVENT="2014p051675"
DBDURATION=730
RUNTIME=864000
SPEEDUP=10


function usage(){
cat <<EOF
Usage: $0 [Options] 
Build or run docker $IMAGE

Optional Arguments:
    -h, --help              Show this message.
    -b, --build             Rebuild the image.
    -i, --interactive       Start the container with a bash prompt.
    -r, --run               Run a simultion (defaults to event $EVENT)
    --event                 Provide an alternative event to simulate
    --image                 Provide alternative image name.
    --tag                   Provide alternative tag
    --dbduration            Provide alternative template database duration in days (default: $DBDURATION)
    --runtime               Provide alternative run duration in seconds (default: $RUNTIME)
    --speedup               Provide alternative speed-up multiplier (default: $SPEEDUP)
EOF
}

# Processing command line options
if [[ $# -eq 0 ]] ; then
    usage
    exit 1
fi

while [ $# -gt 0 ]
do
    case "$1" in
        -b | --build) BUILD=true;;
        -i | --interactive) INTERACTIVE=true;;
        -r | --run) RUN=true;shift;;
        --event) EVENT="$2";shift;;
        --image) IMAGE="$2";shift;;
        --tag) TAG="$2";shift;;
        --dbduration) DBDURATION="$2";shift;;
        --runtime) RUNTIME="$2";shift;;
        --speedup) SPEEDUP="$2";shift;;
        -h) usage; exit 0;;
        -*) echo "Unknown args: $1"; usage; exit 1;;
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
    --rm -m 16g --cpus=6 --name simulator\
    -v $DETECTION_HOSTPATH:$DETECTION_DOCKERPATH \
    $IMAGE rteqcorrscan-simulation \
    --quake $EVENT \
    --config NZ_past_seq_config.yml \
    --db-duration $DBDURATION \
    --runtime $RUNTIME \
    --client GEONET \
    --speed-up $SPEEDUP \
    --working-dir $DETECTION_DOCKERPATH
  # Record memory usage to plot later
  # while true; do docker stats --no-stream --format '{{.MemUsage}}' CONTAINER_ID | cut -d '/' -f 1 >>docker-stats; sleep 1; done
fi

if [ "${INTERACTIVE}" == "true" ]; then
  docker run -it --rm \
      -m 16g --cpus=6 \
      -v $DETECTION_HOSTPATH:$DETECTION_DOCKERPATH \
      --entrypoint /bin/bash \
      ${IMAGE}:${TAG} 
  exit 0
fi

