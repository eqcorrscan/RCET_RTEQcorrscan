# Local paths
DETECTION_HOSTPATH="${PWD}/detections"

# Container paths
BASE_PATH="/tmp/outputs"
DETECTION_DOCKERPATH="${BASE_PATH}/detections"

IMAGE="rteq-simulator"

docker build -t $IMAGE .
# Usually you should be able to re-use the old image, for changes to the rteqcorrscan or eqcorrscan repos we need to rebuild
# docker build --no-cache -t $IMAGE .

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
