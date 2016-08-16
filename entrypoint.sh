#!/bin/bash

SERVICES=${SERVICES:-"st2actionrunner st2api st2auth st2chatops st2garbagecollector st2notifier st2resultstracker st2rulesengine st2sensorcontainer st2stream mistral nginx"}

for SERVICE in $SERVICES; do
  systemctl enable $SERVICE
done

# launch systemd
exec /usr/sbin/init
