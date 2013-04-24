MBaaS_Load_Test
===============

Device simulator for MBaaS, for testing the push service

1. Single instance
vi config/single.json
npm install
node mobile.js ./config/single.json

2. Multi instances
prepare the config files in one dir
./create_instances.sh <your config file dir>

once you want to delete those instances, run ./remove_instances.sh
