#!/bin/bash

export REG_SERVER="10.110.185.92"
export REG_PORT="10080"
export PN_SERVER="10.110.185.92"
export PN_PORT="8080"
export PE_SERVER="10.110.185.90"
export PE_PORT="80"

export DEVICE_ID_FROM=100000
export DEVICE_NUM=500

export APP_KEY1="100"
export TOPIC="sports-$$"


. `dirname $0`/../scripts/config.def

base_dir=/tmp/test2
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
  "appKeys": [ "${APP_KEY1}" ],
  "topics": {"${APP_KEY1}": ["${TOPIC}"]}
}
EOF
done

echo "Create ${DEVICE_NUM} mobile instances"
`dirname $0`/../scripts/create_instances.sh ${etc_dir}

echo "sleep $((DEVICE_NUM/10))"
sleep $((DEVICE_NUM/10))

cp -rf ${LOG_DIR}/* ${result_dir}

echo "Remove mobile instances"
`dirname $0`/../scripts/remove_instances.sh

echo ""
date
echo ""

fail=0
for file in `ls ${result_dir}`; do
  egrep "Error|Closed" ${result_dir}/${file} > /dev/null 2>&1
  if [ $? -eq 0 ]; then
    echo "ERROR: check log file ${result_dir}/${file}"
    fail=$((fail+1))
  fi
done

echo "Failed connections: ${fail}"
echo ""

if [ ${fail} -eq 0 ]; then
  echo ===============
  echo OK
  echo ===============
fi
