INTERVAL=1
OUTNAME="monitor_container.out"
CONTAINER="RTEQCC"


function usage(){
cat <<EOF
Usage $0 [Options]
Monitor computational use of docker container using docker stats

Arguments:
    -c, --container         Container name (default: $CONTAINER)
    -i, --interval          Interval in seconds to probe (default: $INTERVAL)
    -o, --outfile           Outfile to write to (default: $OUTFILE)
EOF
}


function update_file() {
  { docker stats $CONTAINER --no-stream --format "table {{.Name}},{{.CPUPerc}},{{.MemUsage}},{{.NetIO}},{{.BlockIO}},{{.PIDs}}" | tail -n1 | sed -z 's/\n/,/g;s/,$/\n/' & echo $(date +'%Y/%m/%dT%H:%M:%S'); } | tee --append $OUTNAME;
}

function overwrite() { echo -e "\r\033[1A\033[0K$@"; }

# Process cmd-line args
# if [[ $# -eq 0 ]] ; then
#     usage
#     exit 1
# fi


while [ $# -gt 0 ]
do
    case "$1" in
        -c | --container) CONTAINER=$2;shift;;
        -i | --interval) INTERVAL=$2;shift;;
        -o | --outfile) OUTNAME=$2;shift;;
        -h) usage; exit 0;;
        -*) echo "Unknown args: $1"; usage; exit 1;;
    esac
    shift
done


while true;
do
    stats=$(docker stats $CONTAINER --no-stream --format "table {{.Name}},{{.CPUPerc}},{{.MemUsage}},{{.NetIO}},{{.BlockIO}},{{.PIDs}}" | tail -n1)
    stats_tabbed=$(echo $stats | sed "s/\,/\\t/g")
    timestamp=$(date +'%Y/%m/%dT%H:%M:%S')
    # Print to screen
    overwrite && echo -n $timestamp && echo -n -e "\t"$stats_tabbed
    # Print to file
    echo -n $timestamp"," >>$OUTNAME
    echo $stats >> $OUTNAME
    sleep $INTERVAL;
done
