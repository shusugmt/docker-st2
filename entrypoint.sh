#!/bin/bash

[ -v MONGO_HOST ] && \
  crudini --set /etc/st2/st2.conf database host $MONGO_HOST
[ -v MONGO_PASSWORD ] && \
  crudini --set /etc/st2/st2.conf database password $MONGO_PASSWORD
[ -v RABBITMQ_HOST ] && \
  crudini --set /etc/st2/st2.conf messaging url amqp://guest:guest@${RABBITMQ_HOST}:5672/ && \
  crudini --set /etc/mistral/mistral.conf DEFAULT transport_url rabbit://guest:guest@${RABBITMQ_HOST}:5672
([ -v POSTGRES_HOST ] || [ -v POSTGRES_PASSWORD ]) && \
  crudini --set /etc/mistral/mistral.conf database connection postgresql://mistral:${POSTGRES_PASSWORD:-StackStorm}@${POSTGRES_HOST:-127.0.0.1}/mistral
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

SERVICES=${SERVICES:-"st2actionrunner st2api st2auth st2garbagecollector st2notifier st2resultstracker st2rulesengine st2sensorcontainer st2stream mistral nginx"}

for SERVICE in $SERVICES; do
  systemctl enable $SERVICE
done

if [ "${HA,,}" = "true" ]; then
  cp /etc/nginx/conf.d/st2.conf.blueprint.sample /etc/nginx/conf.d/st2.conf
  crudini --set /etc/st2/st2.conf mistral v2_base_url https://${HA_FRONT_HOST}/mistral/v2
  crudini --set /etc/st2/st2.conf mistral api_url https://${HA_FRONT_HOST}/api
  crudini --set /etc/st2/st2.conf mistral insecure True

  # HA: st2rulesengine timer
  crudini --set /etc/st2/st2.conf timer enable False
  if [ "${HA_ST2RULESENGINE,,}" = "primary" ]; then
    # enable timer for st2rulesengine only on "primary" node as described in the doc
    crudini --set /etc/st2/st2.conf timer enable True
  fi

  # HA: st2sensorcontainer
  systemctl disable st2sensorcontainer
  systemctl mask st2sensorcontainer
  if [ "${HA_ST2SENSORCONTAINER,,}" = "primary" ]; then
    # enable st2sensorcontainer only on "primary" node
    # currently sensor partitioning just provides performance, not HA
    systemctl unmask st2sensorcontainer
    systemctl enable st2sensorcontainer
  fi
fi

# assure postgres db schema being up-to-date
/opt/stackstorm/mistral/bin/mistral-db-manage --config-file /etc/mistral/mistral.conf upgrade head
/opt/stackstorm/mistral/bin/mistral-db-manage --config-file /etc/mistral/mistral.conf populate
/opt/stackstorm/mistral/bin/mistral-db-manage --config-file /etc/mistral/mistral.conf current

# run custom init scripts
for f in /entrypoint.d/*; do
  case "$f" in
    *.sh) echo "$0: running $f"; . "$f" ;;
    *)    echo "$0: ignoring $f" ;;
  esac
  echo
done

# launch systemd
exec /usr/sbin/init
