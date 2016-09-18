#! /bin/bash

USERID="admin"
PASSWD="admin"
PORT="8080"
AMBARI_SERVER="localhost"

CLUSTER=`curl -s -u $USERID:$PASSWD -X GET http://$AMBARI_SERVER:$PORT/api/v1/clusters | grep -Po '(?<="cluster_name" : ")[^"]*'`

# Get system info from slave hosts
HOST=`curl -s -u $USERID:$PASSWD -X GET http://$AMBARI_SERVER:$PORT/api/v1/clusters/$CLUSTER/services/YARN/components/NODEMANAGER?fields=host_components | grep -Po '(?<="host_name" : ")[^"]*'`
HOST=`echo $HOST | awk '{print $1}'`

CPU=`curl -s -u $USERID:$PASSWD -X GET http://$AMBARI_SERVER:$PORT/api/v1/clusters/$CLUSTER/hosts/$HOST?fields=metrics/cpu/cpu_num | grep -Po '(?<="cpu_num" : )[^.]*'`
MEMORY=`curl -s -u $USERID:$PASSWD -X GET http://$AMBARI_SERVER:$PORT/api/v1/clusters/$CLUSTER/hosts/$HOST?fields=metrics/memory/mem_total | grep -Po '(?<="mem_total" : )[^\n]*'`
MEMORY=`python -c "from math import ceil; print int(ceil($MEMORY / pow(1024, 2)))"`

# Use yarn-utils.py to calculate value of parameters
CONFIG=`python yarn-utils.py -c $CPU -m $MEMORY -d 1`

YARN_MINIMUM_ALLOCATION=`echo $CONFIG | grep -Po '(?<=yarn.scheduler.minimum-allocation-mb=)[^\s]*' | grep -o '[0-9]*'`
YARN_MAXIMUM_ALLOCATION=`echo $CONFIG | grep -Po '(?<=yarn.scheduler.maximum-allocation-mb=)[^\s]*' | grep -o '[0-9]*'`
YARN_NODEMANAGER_MEMORY=`echo $CONFIG | grep -Po '(?<=yarn.nodemanager.resource.memory-mb=)[^\s]*' | grep -o '[0-9]*'`

MAPREDUCER_MAP_MEMORY=`echo $CONFIG | grep -Po '(?<=mapreduce.map.memory.mb=)[^\s]*' | grep -o '[0-9]*'`
MAPREDUCER_MAP_JAVA_OPTS=`echo $CONFIG | grep -Po '(?<=mapreduce.map.java.opts=)[^\s]*' | grep -o '[0-9]*'`
MAPREDUCER_REDUCE_MEMORY=`echo $CONFIG | grep -Po '(?<=mapreduce.reduce.memory.mb=)[^\s]*' | grep -o '[0-9]*'`
MAPREDUCER_REDUCE_JAVA_OPTS=`echo $CONFIG | grep -Po '(?<=mapreduce.reduce.java.opts=)[^\s]*' | grep -o '[0-9]*'`
MAPREDUCE_SORT=`echo $CONFIG | grep -Po '(?<=mapreduce.task.io.sort.mb=)[^\s]*' | grep -o '[0-9]*'`

YARN_MAPREDUCE_RESOURCE=`echo $CONFIG | grep -Po '(?<=yarn.app.mapreduce.am.resource.mb=)[^\s]*' | grep -o '[0-9]*'`
YARN_MAPREDUCE_COMMAND_OPTS=`echo $CONFIG | grep -Po '(?<=yarn.app.mapreduce.am.command-opts=)[^\s]*' | grep -o '[0-9]*'`

# Send the configurations to Ambari Server by using configs.sh
/var/lib/ambari-server/resources/scripts/configs.sh -u $USERID -p $PASSWD -port $PORT set $AMBARI_SERVER $CLUSTER yarn-site "yarn.scheduler.minimum-allocation-mb" "$YARN_MINIMUM_ALLOCATION"
/var/lib/ambari-server/resources/scripts/configs.sh -u $USERID -p $PASSWD -port $PORT set $AMBARI_SERVER $CLUSTER yarn-site "yarn.scheduler.maximum-allocation-mb" "$YARN_MAXIMUM_ALLOCATION"
/var/lib/ambari-server/resources/scripts/configs.sh -u $USERID -p $PASSWD -port $PORT set $AMBARI_SERVER $CLUSTER yarn-site "yarn.nodemanager.resource.memory-mb" "$YARN_NODEMANAGER_MEMORY"

/var/lib/ambari-server/resources/scripts/configs.sh -u $USERID -p $PASSWD -port $PORT set $AMBARI_SERVER $CLUSTER mapred-site "mapreduce.map.memory.mb" "$MAPREDUCER_MAP_MEMORY"
/var/lib/ambari-server/resources/scripts/configs.sh -u $USERID -p $PASSWD -port $PORT set $AMBARI_SERVER $CLUSTER mapred-site "mapreduce.map.java.opts" "$MAPREDUCER_MAP_JAVA_OPTS"
/var/lib/ambari-server/resources/scripts/configs.sh -u $USERID -p $PASSWD -port $PORT set $AMBARI_SERVER $CLUSTER mapred-site "mapreduce.reduce.memory.mb" "$MAPREDUCER_REDUCE_MEMORY"
/var/lib/ambari-server/resources/scripts/configs.sh -u $USERID -p $PASSWD -port $PORT set $AMBARI_SERVER $CLUSTER mapred-site "mapreduce.reduce.java.opts" "$MAPREDUCER_REDUCE_JAVA_OPTS"
/var/lib/ambari-server/resources/scripts/configs.sh -u $USERID -p $PASSWD -port $PORT set $AMBARI_SERVER $CLUSTER mapred-site "mapreduce.task.io.sort.mb" "$MAPREDUCE_SORT"

/var/lib/ambari-server/resources/scripts/configs.sh -u $USERID -p $PASSWD -port $PORT set $AMBARI_SERVER $CLUSTER mapred-site "yarn.app.mapreduce.am.resource.mb" "$YARN_MAPREDUCE_RESOURCE"
/var/lib/ambari-server/resources/scripts/configs.sh -u $USERID -p $PASSWD -port $PORT set $AMBARI_SERVER $CLUSTER mapred-site "yarn.app.mapreduce.am.command-opts" "$YARN_MAPREDUCE_COMMAND_OPTS"


# Restart all affected services
cp restart_all_affected_template.json restart_all_affected.json

# Get all affected hosts
HISTORYSERVER_HOST=`curl -s -u $USERID:$PASSWD -X GET http://$AMBARI_SERVER:$PORT/api/v1/clusters/$CLUSTER/services/MAPREDUCE2/components/HISTORYSERVER?fields=host_components | grep -Po '(?<="host_name" : ")[^"]*'`
MAPREDUCE2_CLIENT_HOSTS=`curl -s -u $USERID:$PASSWD -X GET http://$AMBARI_SERVER:$PORT/api/v1/clusters/$CLUSTER/services/MAPREDUCE2/components/MAPREDUCE2_CLIENT?fields=host_components | grep -Po '(?<="host_name" : ")[^"]*'`
MAPREDUCE2_CLIENT_HOSTS=`echo $MAPREDUCE2_CLIENT_HOSTS | sed -e "s|\s|, |g"`

APP_TIMELINE_SERVER_HOST=`curl -s -u $USERID:$PASSWD -X GET http://$AMBARI_SERVER:$PORT/api/v1/clusters/$CLUSTER/services/YARN/components/APP_TIMELINE_SERVER?fields=host_components | grep -Po '(?<="host_name" : ")[^"]*'`
NODEMANAGER_HOSTS=`curl -s -u $USERID:$PASSWD -X GET http://$AMBARI_SERVER:$PORT/api/v1/clusters/$CLUSTER/services/YARN/components/NODEMANAGER?fields=host_components | grep -Po '(?<="host_name" : ")[^"]*'`
NODEMANAGER_HOSTS=`echo $NODEMANAGER_HOSTS | sed -e "s|\s|, |g"`
RESOURCEMANAGER_HOST=`curl -s -u $USERID:$PASSWD -X GET http://$AMBARI_SERVER:$PORT/api/v1/clusters/$CLUSTER/services/YARN/components/RESOURCEMANAGER?fields=host_components | grep -Po '(?<="host_name" : ")[^"]*'`
YARN_CLIENT_HOSTS=`curl -s -u $USERID:$PASSWD -X GET http://$AMBARI_SERVER:$PORT/api/v1/clusters/$CLUSTER/services/YARN/components/YARN_CLIENT?fields=host_components | grep -Po '(?<="host_name" : ")[^"]*'`
YARN_CLIENT_HOSTS=`echo $YARN_CLIENT_HOSTS | sed -e "s|\s|, |g"`

sed -i "s|HISTORYSERVER_HOST|$HISTORYSERVER_HOST|g" restart_all_affected.json
sed -i "s|MAPREDUCE2_CLIENT_HOSTS|$MAPREDUCE2_CLIENT_HOSTS|g" restart_all_affected.json

sed -i "s|APP_TIMELINE_SERVER_HOST|$APP_TIMELINE_SERVER_HOST|g" restart_all_affected.json
sed -i "s|NODEMANAGER_HOSTS|$NODEMANAGER_HOSTS|g" restart_all_affected.json
sed -i "s|RESOURCEMANAGER_HOST|$RESOURCEMANAGER_HOST|g" restart_all_affected.json
sed -i "s|YARN_CLIENT_HOSTS|$YARN_CLIENT_HOSTS|g" restart_all_affected.json

# Send the request to restart all affected services
curl -s -u $USERID:$PASSWD -X POST -H 'X-Requested-By: ambari' -d @restart_all_affected.json http://$AMBARI_SERVER:$PORT/api/v1/clusters/$CLUSTER/requests
