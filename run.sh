#!/bin/bash

set -m
CONFIG_FILE="/config/config.toml"

#Dynamically change the value of 'max-open-shards' to what 'ulimit -n' returns
sed -i "s/^max-open-shards.*/max-open-shards = $(ulimit -n)/" ${CONFIG_FILE}

#Configure InfluxDB Cluster
if [ -n "${FORCE_HOSTNAME}" ]; then
    if [ "${FORCE_HOSTNAME}" == "auto" ]; then
        #set hostname with IPv4 eth0
        HOSTIPNAME=$(ip a show dev eth0 | grep inet | grep eth0 | sed -e 's/^.*inet.//g' -e 's/\/.*$//g')
        /usr/bin/perl -p -i -e "s/^# hostname.*$/hostname = \"${HOSTIPNAME}\"/g" ${CONFIG_FILE}
    else
        /usr/bin/perl -p -i -e "s/^# hostname.*$/hostname = \"${FORCE_HOSTNAME}\"/g" ${CONFIG_FILE}
    fi
fi

if [ -n "${SEEDS}" ]; then
    SEEDS=$(eval SEEDS=$SEEDS ; echo $SEEDS | grep '^\".*\"$' || echo "\""$SEEDS"\"" | sed -e 's/, */", "/g')
    /usr/bin/perl -p -i -e "s/^# seed-servers.*$/seed-servers = [${SEEDS}]/g" ${CONFIG_FILE}
fi

if [ -n "${REPLI_FACTOR}" ]; then
    /usr/bin/perl -p -i -e "s/replication-factor = 1/replication-factor = ${REPLI_FACTOR}/g" ${CONFIG_FILE}
fi

# Add UDP support
if [ -n "${UDP_DB}" ]; then
    sed -i -r -e "/^\s+\[input_plugins.udp\]/, /^$/ { s/false/true/; s/#//g; s/\"\"/\"${UDP_DB}\"/g; }" ${CONFIG_FILE}
fi

# Add GRAPHITE support
if [ -n "${GRAPHITE_DB}" ]; then
    sed -i -r -e "/^\s+\[input_plugins.graphite\]/, /^$/ { s/false/true/; s/#//g; s/\"\"/\"${GRAPHITE_DB}\"/g; }" ${CONFIG_FILE}
fi

echo "=> Starting InfluxDB ..."

exec /opt/influxdb/influxd -config=${CONFIG_FILE}

