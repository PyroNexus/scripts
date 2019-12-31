#!/bin/bash
#
# Author: Michael Fazio (sandstone.io)
# Modification by Straightpool (https://straightpool.github.io/about/) 
#
# This script monitors a Jormungandr node for "liveness" and executes a shutdown if the node is determined
# to be "stuck". A node is "stuck" if the time elapsed since last block exceeds the sync tolerance 
# threshold. The script does NOT perform a restart on the Jormungandr node. Instead we rely on process 
# managers such as systemd to perform restarts.
#
# Modification: The script also considers a node stuck if it is too long offline or in bootstrap mode. It then uses systemd 
# to actually restart the node, as a simple shutdown won't work in these scenarios
# Run the script with sudo rights to make use of this added functionality


POLLING_INTERVAL_SECONDS=30
SYNC_TOLERANCE_SECONDS=240
REST_API="http://127.0.0.1:9099/api"
BOOTSTRAP_TIME=$SECONDS

while true; do

    LAST_BLOCK=$(/home/sl/.cargo/bin/jcli rest v0 node stats get --output-format json --host $REST_API 2> /dev/null)
    LAST_BLOCK_HEIGHT=$(echo $LAST_BLOCK | jq -r .lastBlockHeight)
    LAST_BLOCK_DATE=$(echo $LAST_BLOCK | jq -r .lastBlockTime)
    LAST_BLOCK_TIME=$(date -d$LAST_BLOCK_DATE +%s 2> /dev/null)
    CURRENT_TIME=$(date +%s)
    DIFF_SECONDS=$((CURRENT_TIME - LAST_BLOCK_TIME))

    if ((LAST_BLOCK_TIME > 0)); then
        if ((DIFF_SECONDS > SYNC_TOLERANCE_SECONDS)); then
            echo "Jormungandr out-of-sync. Time difference of $DIFF_SECONDS seconds. Shutting down node..."
            /home/sl/.cargo/bin/jcli rest v0 shutdown get --host $REST_API
            BOOTSTRAP_TIME=$SECONDS
        else
            echo "Jormungandr synchronized. Time difference of $DIFF_SECONDS seconds. Last block height $LAST_BLOCK_HEIGHT."
            BOOTSTRAP_TIME=$SECONDS
        fi
    else
        BOOTSTRAP_ELAPSED_TIME=$(($SECONDS - $BOOTSTRAP_TIME))
        echo "Jormungandr node is offline or bootstrapping since $BOOTSTRAP_ELAPSED_TIME..."
        if ((BOOTSTRAP_ELAPSED_TIME > SYNC_TOLERANCE_SECONDS)); then
          echo "Jormungandr stuck in bootstrap or offline too long. Attempting to restart node..."
          systemctl stop jormungandr
          sleep 5
          systemctl start jormungandr
       fi
    fi

    sleep $POLLING_INTERVAL_SECONDS
done