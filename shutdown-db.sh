kill $(ps aux | grep mongod | grep config | grep mongodb-single | awk '{print $2}')
