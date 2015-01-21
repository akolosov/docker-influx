FROM dockerfile/ubuntu

# Install InfluxDB
ENV INFLUXDB_VERSION latest
RUN curl -s -o /tmp/influxdb_latest_amd64.deb https://s3.amazonaws.com/influxdb/influxdb_${INFLUXDB_VERSION}_amd64.deb && \
  dpkg -i /tmp/influxdb_latest_amd64.deb && \
  rm /tmp/influxdb_latest_amd64.deb && \
  rm -rf /var/lib/apt/lists/*

ADD config.toml /config/config.toml
ADD run.sh /run.sh
RUN chmod +x /*.sh

EXPOSE 8083 8086 8090 8099 4444/udp 2003/udp

VOLUME ["/data"]

RUN mkdir -p /data/logs
RUN mkdir -p /data/raft
RUN mkdir -p /data/wal
RUN mkdir -p /data/db

WORKDIR /data

ENTRYPOINT ["/bin/bash", "/run.sh"]
