#!/bin/bash
#
# Author: Michael Fazio (sandstone.io)
# Modification by Straightpool (https://straightpool.github.io/about/) 
# Modification by PyroNexus (https://pyronexus.com)
#
# This script monitors a Jormungandr node for "liveness" and executes a shutdown if the node is determined
# to be "stuck". A node is "stuck" if the time elapsed since last block exceeds the sync tolerance 
# threshold. The script does NOT perform a restart on the Jormungandr node. Instead we rely on process 
# managers such as systemd to perform restarts.
#
# Modifications: 
# - Removed a load of confusing nested logging logic which had zero benefit
# - Provided sanity to the configuration parameters
#
# Version 3.0

## CONFIGURATION PARAMETERS

POLLING_INTERVAL_SECONDS=30
SYNC_TOLERANCE_SECONDS=300
BOOTSTRAP_TOLERANCE_SECONDS=480
REST_SCHEME="http"
REST_HOST="127.0.0.1"
REST_PORT="3100"
REST_URI="api"
SYSTEMCTL_DAEMON_NAME="jormungandr.service"
JCLI=/opt/jormungandr/jcli
## END OF CONFIGURATION PARAMETERS



REST_API="$REST_SCHEME://$REST_HOST:$REST_PORT/$REST_URI"
BOOTSTRAP_TIME=$SECONDS

while true; do

    LAST_BLOCK=$($JCLI rest v0 node stats get --output-format json --host $REST_API 2> /dev/null)
    LAST_BLOCK_HEIGHT=$(echo $LAST_BLOCK | jq -r .lastBlockHeight)
    LAST_BLOCK_DATE=$(echo $LAST_BLOCK | jq -r .lastBlockTime)
    UPTIME=$(echo $LAST_BLOCK | jq -r .uptime)
    LAST_BLOCK_TIME=$(date -d$LAST_BLOCK_DATE +%s 2> /dev/null)
    CURRENT_TIME=$(date +%s)
    if ((LAST_BLOCK_TIME > 0)); then  
        DIFF_SECONDS=$((CURRENT_TIME - LAST_BLOCK_TIME))
        if ((DIFF_SECONDS > SYNC_TOLERANCE_SECONDS)); then
            echo "Jormungandr out-of-sync. Time difference of $DIFF_SECONDS seconds. Shutting down node with uptime $UPTIME..."
            $JCLI rest v0 shutdown get --host $REST_API
            BOOTSTRAP_TIME=$SECONDS
            DIFF_SECONDS=0
        else
            BOOTSTRAP_TIME=$SECONDS
            echo "Jormungandr synchronized. Time difference of $DIFF_SECONDS seconds. Last block height $LAST_BLOCK_HEIGHT."
         fi
    else
        BOOTSTRAP_ELAPSED_TIME=$(($SECONDS - $BOOTSTRAP_TIME))
        if ((BOOTSTRAP_ELAPSED_TIME > BOOTSTRAP_TOLERANCE_SECONDS)); then
          echo "Jormungandr stuck in bootstrap or offline too long. Attempting to restart node..."
          systemctl stop $SYSTEMCTL_DAEMON_NAME
          sleep 5
          systemctl start $SYSTEMCTL_DAEMON_NAME
          BOOTSTRAP_TIME=$SECONDS
       else
          echo "Jormungandr node is offline or bootstrapping since $BOOTSTRAP_ELAPSED_TIME..."
       fi
    fi

    sleep $POLLING_INTERVAL_SECONDS
done