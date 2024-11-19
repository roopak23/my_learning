#!/bin/bash
set -ex

# The Main
if grep isMaster /mnt/var/lib/info/instance.json | grep true;
then
    echo "Get primary IP"
    PRIMARY_IP=$(/sbin/ifconfig eth0 | grep 'inet' | cut -d: -f2 | awk '{ print $2}' | xargs)

    echo "Master Node: Setting Hive location IP - $PRIMARY_IP"
    META_LOCATIONS=$(hive --service metatool -listFSRoot | grep "hdfs://")

    for META in $META_LOCATIONS
    do
        echo "Existing meta location: $META"
        META_NOFS="${META:7}"
        HIVE_IP="${META_NOFS%:*}"
        if [[ "$PRIMARY_IP" == "$HIVE_IP" ]]; then
            echo "IPs are equal, no need to update"
        else
            echo "IPs are different, updating Hive location"
            NEW_IP="${META/$HIVE_IP/$PRIMARY_IP}"
            hive --service metatool -updateLocation "$NEW_IP" "$META"
        fi
    done
    exit $?
else
    echo "Core Node: Not setting Hive location IP"
fi

exit 0
