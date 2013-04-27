#!/bin/bash

export REG_SERVER="10.110.185.92"
export REG_PORT="10080"
export PN_SERVER="10.110.185.92"
export PN_PORT="10280"
export PE_SERVER="10.110.185.90"
export PE_PORT="80"

export DEVICE_ID_FROM=100000
export DEVICE_NUM=10

export APP_KEY1="300"
export APP_KEY2="301"

export TOPIC="sports-$$"

export MESSAGE_NUM=20
export MESSAGE_PRE="sports-news-"

. `dirname $0`/../scripts/config.def

base_dir=/tmp/test1
etc_dir=${base_dir}/etc
rm -rf ${etc_dir} > /dev/null 2>&1
mkdir -p ${etc_dir}

result_dir=${base_dir}/result
rm -rf ${result_dir} > /dev/null 2>&1
mkdir -p ${result_dir}

echo "Create config files, dir: ${etc_dir}"

for n in `seq 1 ${DEVICE_NUM}`
do
deviceid=$$-$((n+DEVICE_ID_FROM))
cat > ${etc_dir}/${deviceid}.json << EOF
{
  "regServerHost": "${REG_SERVER}",
  "regServerPort": "${REG_PORT}",
  "pushNetworkHost": "${PN_SERVER}",
  "pushNetworkPort": "${PN_PORT}",
  "pushEngineHost": "${PE_SERVER}",
  "pushEnginePort": "${PE_PORT}",
  "deviceFingerprint": "${deviceid}",
  "appKeys": [ "${APP_KEY1}", "${APP_KEY2}" ],
  "topics": {"${APP_KEY1}": ["${TOPIC}"], "${APP_KEY2}": ["${TOPIC}"]}
}
EOF
done

echo "Create ${DEVICE_NUM} mobile instances"
`dirname $0`/../scripts/create_instances.sh ${etc_dir}

echo "sleep ${DEVICE_NUM}"
sleep ${DEVICE_NUM}

echo "Send ${MESSAGE_NUM} messages from push engine."
for n in `seq -w 1 ${MESSAGE_NUM}`; do
  echo "topic: ${TOPIC}, msg: ${MESSAGE_PRE}${n}"
  curl -X POST -d "msg=${MESSAGE_PRE}${n}" http://${PE_SERVER}:${PE_PORT}/event/${TOPIC}
done

echo "sleep ${MESSAGE_NUM}"
sleep ${MESSAGE_NUM}

cp -rf ${LOG_DIR}/* ${result_dir}

echo "Remove mobile instances"
`dirname $0`/../scripts/remove_instances.sh

echo ""

# template result
seq -w 1 ${MESSAGE_NUM} > ${base_dir}/template.tmp
seq -w 1 ${MESSAGE_NUM} >> ${base_dir}/template.tmp
cat ${base_dir}/template.tmp | sort > ${base_dir}/template
rm -f ${base_dir}/template.tmp

ok=0
for file in `ls ${result_dir}`; do
  grep "${MESSAGE_PRE}" ${result_dir}/${file} | sed "s/^.*${MESSAGE_PRE}//g" | sed "s/\".*$//g" | sort > ${base_dir}/result.tmp
  diff ${base_dir}/result.tmp ${base_dir}/template > /dev/null 2>&1
  if [ $? -ne 0 ]; then
    echo "ERROR: check log file ${result_dir}/${file}"
    ok=1
  fi
done

if [ ${ok} -eq 0 ]; then
  echo ===============
  echo OK
  echo ===============
fi
