#!/bin/bash

[ -v MONGO_HOST ] && \
  crudini --set /etc/st2/st2.conf database host $MONGO_HOST
[ -v RABBITMQ_HOST ] && \
  crudini --set /etc/st2/st2.conf messaging url amqp://guest:guest@${RABBITMQ_HOST}:5672/ && \
  crudini --set /etc/mistral/mistral.conf DEFAULT transport_url rabbit://guest:guest@${RABBITMQ_HOST}:5672
[ -v POSTGRES_HOST ] && \
  crudini --set /etc/mistral/mistral.conf database connection postgresql://mistral:StackStorm@${POSTGRES_HOST}/mistral
[ -v REDIS_HOST ] && \
  crudini --set /etc/st2/st2.conf coordination url redis://${REDIS_HOST}:6379

[ -v WORKERS ] && \
  echo WORKERS=$WORKERS > /etc/sysconfig/st2actionrunner

[ -v MOUNT_ST2_PACKS ] && \
  mkdir -p /opt/stackstorm/packs && \
  mount $MOUNT_ST2_PACKS /opt/stackstorm/packs
[ -v MOUNT_ST2_CONFIGS ] && \
  mkdir -p /opt/stackstorm/configs && \
  mount $MOUNT_ST2_CONFIGS /opt/stackstorm/configs

SERVICES=${SERVICES:-"st2actionrunner st2api st2auth st2garbagecollector st2notifier st2resultstracker st2rulesengine st2sensorcontainer st2stream mistral nginx sshd"}

for SERVICE in $SERVICES; do
  systemctl enable $SERVICE
done

# launch systemd
exec /usr/sbin/init
