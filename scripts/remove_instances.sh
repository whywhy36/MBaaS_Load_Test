#!/bin/bash

. `dirname $0`/config.def

[ ! -d ${PID_DIR} ] && exit

kill -9 `ls ${PID_DIR}` > /dev/null 2>&1
rm -f ${PID_DIR}/*

[ ! -d ${LOG_DIR} ] && exit

mv ${LOG_DIR} ${LOG_DIR}_`date +%Y%m%d%H%M%S`
