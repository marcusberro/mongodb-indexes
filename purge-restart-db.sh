kill $(ps aux | grep mongod | grep config | grep mongodb-single | awk '{print $2}')

sleep 1

rm -rf db
mkdir db

mongod --config mongodb-single.conf --fork
