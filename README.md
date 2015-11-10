docker-influxdb
===============
InfluxDB image


Usage
-----

To create the image `akolosov/influxdb`, execute the following command on akolosov-docker-influxdb folder:

    docker build -t akolosov/influxdb .

You can now push new image to the registry:
    
    docker push akolosov/influxdb

Clustering
----------
Use :
* `-e FORCE_HOSTNAME="<whatever>" ` to force the hostname in the config file to be set to 'whatever'

Example on a single docker host :
* launch first container :
```
docker run -p 8083:8083 -p 8086:8086 -p 8088:8088  \
  -e FORCE_HOSTNAME="influx-master"  -d --name influx-master akolosov/influxdb
```
* then launch one or more "slaves":
```
docker run --link influx-master:master -p 8083 -p 8086 -p 8088 \
  -e FORCE_HOSTNAME="influx-slave" -d --name influx-slave akolosov/influxdb -join master:8088
```
