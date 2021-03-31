#!/usr/bin/env bash

# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -e               # exit on error

pushd "$(dirname "$0")" # connect to root

ROOT_DIR=$(pwd)
source ${ROOT_DIR}/config.sh

USER_NAME=${SUDO_USER:=$USER}
USER_ID=$(id -u "${USER_NAME}")

# Set the home directory in the Docker container.
DOCKER_HOME_DIR=/home/${USER_NAME}

CMD="bin/disable-safe-mode.sh"
RUNNING_MODE="daemon"

if [ "$#" -ge 1 ] ; then
  CMD="$@"
  RUNNING_MODE="interactive"
fi

HADOOP_HOME=/opt/hadoop/hadoop-${HADOOP_VERSION}

# Create NameNode and DataNode mount points
mkdir -p ${ROOT_DIR}/volume/namenode
mkdir -p ${ROOT_DIR}/volume/datanode0

mkdir -p ${ROOT_DIR}/volume/logs
rm -f ${ROOT_DIR}/volume/logs/*

mkdir -p ${ROOT_DIR}/volume/status
rm -f ${ROOT_DIR}/volume/status/*

if [ $RUNNING_MODE = "interactive" ]; then
  DOCKER_IT="-i -t"
fi

DOCKER_RUN="docker run --rm=true ${DOCKER_IT}
  -v ${ROOT_DIR}/volume/namenode:/opt/volume/namenode
  -v ${ROOT_DIR}/volume/datanode0:/opt/volume/datanode 
  -v ${ROOT_DIR}/volume/status:/opt/volume/status
  -v ${ROOT_DIR}/volume/logs:${HADOOP_HOME}/logs
  -v ${ROOT_DIR}/etc/hadoop/core-site.xml:${HADOOP_HOME}/etc/hadoop/core-site.xml
  -v ${ROOT_DIR}/etc/hadoop/hdfs-site.xml:${HADOOP_HOME}/etc/hadoop/hdfs-site.xml
  -v ${ROOT_DIR}/bin/disable-safe-mode.sh:${HADOOP_HOME}/bin/disable-safe-mode.sh
  -w ${HADOOP_HOME}
  -e HADOOP_HOME=${HADOOP_HOME}
  -e RUNNING_MODE=${RUNNING_MODE}
  -u ${USER_ID}
  --network dike-net
  --name hadoop-disable-safe-mode
  hadoop-${HADOOP_VERSION}-ndp-${USER_NAME} ${CMD} "

eval ${DOCKER_RUN}

popd
