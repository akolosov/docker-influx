FROM akolosov/busybox
MAINTAINER Alexey Kolosov <alexey.kolosov@gmail.com>

# Install InfluxDB
ENV INFLUXDB_VERSION 0.9.4.2
ADD  https://s3.amazonaws.com/influxdb/influxdb_${INFLUXDB_VERSION}_x86_64.tar.gz /tmp/influxdb.tar.gz
RUN  cd /tmp && gunzip -dc influxdb.tar.gz | tar xvf - && \
	cp influxdb_${INFLUXDB_VERSION}_x86_64/opt/influxdb/versions/${INFLUXDB_VERSION}/influx /bin/influx && \
	cp influxdb_${INFLUXDB_VERSION}_x86_64/opt/influxdb/versions/${INFLUXDB_VERSION}/influxd /sbin/influxd && \
	rm -rf influxdb*

EXPOSE 8083 8086 8088

VOLUME ["/data"]

RUN mkdir -p /data/logs
RUN mkdir -p /data/raft
RUN mkdir -p /data/wal
RUN mkdir -p /data/db

RUN chmod -R 0777 /data

WORKDIR /data

# Generate a default config
RUN /sbin/influxd config > /etc/influxdb.toml

# Use /data for all disk storage
RUN sed -i 's/dir = "\/.*influxdb/dir = "\/data/' /etc/influxdb.toml

ENTRYPOINT ["/sbin/influxd", "--config", "/etc/influxdb.toml"]
