#!/bin/bash

CONFIG_PATH=/data/options.json

HOSTNAME=$(jq --raw-output ".hostname" $CONFIG_PATH)
USERNAME=$(jq --raw-output ".username" $CONFIG_PATH)
PASSWORD=$(jq --raw-output ".password" $CONFIG_PATH)
INTERVAL=$(jq --raw-output ".update_interval" $CONFIG_PATH)

touch /ip.txt

trap cleanup SIGTERM

cleanup()
{
    echo "[$(date +"%F %T")] Cleaning up..."
    rm -rf /ip.txt
}

while true
do
    CUR_IP=$(cat /ip.txt)
    NEW_IP=$(curl -s http://myip.dnsomatic.com/)
    rc=$?

    if [[ $rc == 0 ]]; then
        if [[ "$NEW_IP" != "$CUR_IP" ]]; then
            echo "[$(date +"%F %T")] New IP Detected! Attempting to update $HOSTNAME with $NEW_IP on DNS-O-Matic..."
            ret=$(curl -s -u "$USERNAME:$PASSWORD" "https://updates.dnsomatic.com/nic/update?myip=$NEW_IP&hostname=$HOSTNAME&wildcard=NOCHG&mx=NOCHG&backmx=NOCHG")
            rc=$?
            echo "[$(date +"%F %T")] DNS-O-Matic response: $ret"

            if [[ $rc != 0 ]]; then
                echo "[$(date +"%F %T")] Error updating DNS-O-Matic with $NEW_IP..." 
            else
                ret=$(echo "$NEW_IP" | tee /ip.txt)
                echo "[$(date +"%F %T")] Caching $ret"
            fi
        else
            echo "[$(date +"%F %T")] No IP change, not updating DNS-O-Matic..."    
        fi 
    else
        echo "[$(date +"%F %T")] Error getting current IP address, not updating..."   
    fi

    echo ""
    echo "[$(date +"%F %T")] Waiting $INTERVAL seconds before next IP check..."
    sleep $INTERVAL
done
