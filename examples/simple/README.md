# Quickstart

```
# start containers
docker-compose up -d

# setup mistral
docker-compose exec --user postgres postgres psql -c "CREATE ROLE mistral WITH CREATEDB LOGIN ENCRYPTED PASSWORD 'StackStorm';"
docker-compose exec --user postgres postgres psql -c "CREATE DATABASE mistral OWNER mistral;"
docker-compose exec st2 /opt/stackstorm/mistral/bin/mistral-db-manage --config-file /etc/mistral/mistral.conf upgrade head
docker-compose exec st2 /opt/stackstorm/mistral/bin/mistral-db-manage --config-file /etc/mistral/mistral.conf populate

# register default packs
docker-compose exec st2 st2ctl reload --register-all

# install st2 pack
docker-compose exec st2 st2 run packs.install packs=st2

# restart
docker-compose restart st2

# ready to go!
docker-compose exec st2 bash
```

```
st2 --version
st2 -h
st2 auth test -p changeme

# set token
# this is indeed not necessary because credentials are already configured in /root/.st2/config
export ST2_AUTH_TOKEN=$(st2 auth test -p changeme -t)

st2 run core.local -- date -R
st2 execution list
st2 run core.remote hosts="remote1,remote2" -- uname -a
```

You can also access to Web GUI. Check the docker host IP address and just access `https://docker-host-ip` with your favorite browser.

If you are using docker-machine, you can grab your docker host IP with `docker-machine env hoge`
