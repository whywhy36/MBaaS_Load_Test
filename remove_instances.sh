#!/bin/bash

usage() {
  echo "Usage: $0 <config file dir>"
  exit -1
}

err() {
  echo $1
  exit -1
}

LOG_DIR=/var/tmp/mbaas-test/log
PID_DIR=/var/tmp/mbaas-test/pid
CONFIG_DIR=$1

### environment check

[ $# -ne 1 ] && usage
[ ! -d ${CONFIG_DIR} ] && err "$1 not exist."
[ ! -f ./mobile.js ] && err "mobile.js missed."

which npm > /dev/null 2>&1
[ $? -ne 0 ] && err "npm missed."

which node > /dev/null 2>&1
[ $? -ne 0 ] && err "node missed."

[ ! -d $LOG_DIR ] && mkdir -p $LOG_DIR
[ ! -d $PID_DIR ] && mkdir -p $PID_DIR

### start instances
npm install
[ $? -ne 0 ] && err

for file in `ls ${CONFIG_DIR}/*.json`
do
  log_file=`basename ${file} | sed "s/.json$//g"`.log
  node mobile.js ${file} > ${LOG_DIR}/${log_file} 2>&1 &
  touch ${PID_DIR}/$!
done
