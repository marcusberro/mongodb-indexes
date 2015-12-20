#! /bin/bash

while true; do
   echo " " >> people.json
   curl -s -m 50 https://randomuser.me/api/>> people.json
done
