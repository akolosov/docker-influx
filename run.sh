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

if [ "${PRE_CREATE_DB}" == "**None**" ]; then
    unset PRE_CREATE_DB
fi

if [ "${SSL_CERT}" == "**None**" ]; then
    unset SSL_CERT
fi

if [ "${SSL_SUPPORT}" == "**False**" ]; then
    unset SSL_SUPPORT
fi

# Add UDP support
if [ -n "${UDP_DB}" ]; then
    sed -i -r -e "/^\s+\[input_plugins.udp\]/, /^$/ { s/false/true/; s/#//g; s/\"\"/\"${UDP_DB}\"/g; }" ${CONFIG_FILE}
fi
if [ -n "${UDP_PORT}" ]; then
    sed -i -r -e "/^\s+\[input_plugins.udp\]/, /^$/ { s/4444/${UDP_PORT}/; }" ${CONFIG_FILE}
fi

#SSL SUPPORT (Enable https support on port 8084)
API_URL="http://localhost:8086"
CERT_PEM="/cert.pem"
SUBJECT_STRING="/C=US/ST=NewYork/L=NYC/O=Tutum/CN=*"
if [ -n "${SSL_SUPPORT}" ]; then
    echo "=> SSL Support enabled, using SSl api ..."
    echo "=> Listening on port 8084(https api), disabling port 8086(http api)"
    if [ -n "${SSL_CERT}" ]; then 
        echo "=> Use user uploaded certificate"
        echo -e "${SSL_CERT}" > ${CERT_PEM}
    else
        echo "=> Use self-signed certificate"
        if [  -f ${CERT_PEM} ]; then
            echo "=> Certificate found, skip ..."
        else
            echo "=> Generating certificate ..."
            openssl req -new -newkey rsa:4096 -days 3650 -nodes -x509 -subj ${SUBJECT_STRING} -keyout /server.key -out /server.crt >/dev/null 2>&1
            cat /server.key /server.crt > ${CERT_PEM}
            rm -f /server.key /server.crt
        fi
    fi
    sed -i -r -e 's/^# ssl-/ssl-/g' ${CONFIG_FILE}
fi

echo "=> Starting InfluxDB ..."

/usr/bin/influxdb -config=${CONFIG_FILE} &

tail -f /data/logs/influxdb.log

