MBaaS_Load_Test
===============

Device simulator for MBaaS, for testing the push service

1. Single instance
vi config/single.json
npm install
node mobile.js ./config/single.json

2. Multi instances
-- Create 
prepare the config files in a dir
./create_instances.sh <your config file dir>

-- Delete
./remove_instances.sh

-- log
/var/tmp/mbaas-test/log*
