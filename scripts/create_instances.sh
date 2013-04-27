#!/bin/bash

usage() {
  echo "Usage: $0 <config file dir>"
  exit -1
}

err() {
  echo $1
  exit -1
}

abs_path() {
  path=$PWD
  cd $1
  pwd
  cd ${path}
}

. `dirname $0`/config.def

### environment check

[ $# -ne 1 ] && usage
[ ! -d $1 ] && err "$1 not exist."

which npm > /dev/null 2>&1
[ $? -ne 0 ] && err "npm missed."

which node > /dev/null 2>&1
[ $? -ne 0 ] && err "node missed."

[ ! -d $LOG_DIR ] && mkdir -p $LOG_DIR
[ ! -d $PID_DIR ] && mkdir -p $PID_DIR

### start instances

CONFIG_DIR=`abs_path $1`

npm install > /dev/null 2>&1
[ $? -ne 0 ] && err

cd `dirname $0`/..

num=0
for file in `ls ${CONFIG_DIR}/*.json`
do
  num=$((num+1))
  [ $((num%100)) -eq 0 ] && sleep 2
  log_file=`basename ${file} | sed "s/.json$//g"`.log
  node mobile.js ${file} > ${LOG_DIR}/${log_file} 2>&1 &
  touch ${PID_DIR}/$!
done
