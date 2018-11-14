#!/bin/sh

CONFIG_PATH=/data/options.json

HOSTNAME=$(jq --raw-output ".hostname" $CONFIG_PATH)
USERNAME=$(jq --raw-output ".username" $CONFIG_PATH)
PASSWORD=$(jq --raw-output ".password" $CONFIG_PATH)
INTERVAL=$(jq --raw-output ".update_interval" $CONFIG_PATH)

while true
do
    IP=$(curl -s http://myip.dnsomatic.com/)
    rc=$?

    if [[ $rc == 0 ]]; then

        echo "[$(date +"%F %T")] Attempting to update $HOSTNAME with $IP..."
        ret=$(curl -s -u "$USERNAME:$PASSWORD" "https://updates.dnsomatic.com/nic/update?myip=$IP&hostname=$HOSTNAME&wildcard=NOCHG&mx=NOCHG&backmx=NOCHG")
        rc=$?
        echo "[$(date +"%F %T")] DNS-O-Matic response: $ret"

        if [[ $rc != 0 ]]; then
            
            echo "[$(date +"%F %T")] Error updating DNS-O-Matic with IP $IP..."
        
        fi

    else

        echo "[$(date +"%F %T")] Error getting current IP address, not attempting update..."
    
    fi

    echo ""
    echo "[$(date +"%F %T")] Waiting $INTERVAL seconds before next update..."
    sleep $INTERVAL
done
