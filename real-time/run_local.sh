#!/bin/bash

# Defaults that can be overwritten by the user through cmd line args
IMAGE="rteq-real-time"
TAG="latest"
NAME="RTEQCC"

# Defaults
MEM="20g"
CPUS=8
DETECTDIR="detections"
TEMPLATEDIR="templates"


function usage(){
cat <<EOF
Usage: $0 [Options] 
Build or run docker $IMAGE

Optional Arguments:
    -h, --help              Show this message.
    -b, --build             Rebuild the image.
    -i, --interactive       Start the container with a bash prompt.
    -r, --run               Run a simulation (defaults to event $EVENT)
    -l, --local             Run without a docker container
    --image                 Provide alternative image name.
    --name                  Provide an alternative name for the running image
    --tag                   Provide alternative tag
    --mem                   Set memory limit (default: $MEM)
    --cpu                   Set cpu limit (default: $CPUS)
    --detect-dir            Directory to put detections into (default: $DETECTDIR)
    --template-dir          Directory that templates are stored in (default: $TEMPLATEDIR)
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
        -r | --run) RUN=true;;
        -l | --local) LOCAL=true;;
        --image) IMAGE="$2";shift;;
        --name) NAME="$2";shift;;
        --tag) TAG="$2";shift;;
        --mem) MEM="$2";shift;;
        --cpu) CPUS="$2";shift;;
        --detect-dir) DETECTDIR="$2";shift;;
        --template-dir) TEMPLATEDIR="$2";shift;;
        -h) usage; exit 0;;
        -*) echo "Unknown args: $1"; usage; exit 1;;
esac
shift
done

# Local paths
DETECTION_HOSTPATH="$(pwd -P)/${DETECTDIR}"
TEMPLATE_HOSTPATH="$(pwd -P)/${TEMPLATEDIR}"

# Container paths
BASE_PATH="/tmp/outputs"
DETECTION_DOCKERPATH="${BASE_PATH}/detections"
TEMPLATE_DOCKERPATH="${BASE_PATH}/templates"

if [ ! -d $DETECTION_HOSTPATH ];then
  mkdir $DETECTION_HOSTPATH
  chmod og+wx $DETECTION_HOSTPATH
fi


echo "Working in $DETECTION_HOSTPATH"
echo "Running for $EVENT"


if [ "${LOCAL}" == "true" ]; then
    nohup rteqcorrscan-reactor \
        --config RCET_RTEQC_config.yml > reactor.out 2> reactor.err &
    exit 0
fi


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
    --rm -m $MEM --cpus=$CPUS --name $NAME\
    -v $DETECTION_HOSTPATH:$DETECTION_DOCKERPATH \
    -v $TEMPLATE_HOSTPATH:$TEMPLATE_DOCKERPATH \
    $IMAGE rteqcorrscan-reactor \
    --config RCET_RTEQC_config.yml \
  # Record memory usage to plot later
  # while true; do docker stats --no-stream --format '{{.MemUsage}}' CONTAINER_ID | cut -d '/' -f 1 >>docker-stats; sleep 1; done
fi

if [ "${INTERACTIVE}" == "true" ]; then
  docker run -it --rm \
      -m $MEM --cpus=$CPUS \
      -v $DETECTION_HOSTPATH:$DETECTION_DOCKERPATH \
      -v $TEMPLATE_HOSTPATH:$TEMPLATE_DOCKERPATH \
      --entrypoint /bin/bash \
      ${IMAGE}:${TAG} 
  exit 0
fi

