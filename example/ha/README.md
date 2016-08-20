# HA setup

Contents under following directories should be shared across all st2 nodes. In this setup we use NFS to achieve this.

- `/opt/stackstorm/packs`
- `/opt/stackstorm/configs`


```
# start containers
docker-compose up -d

# register default packs
# we use st2node3 here but you can pick any node from st2node{1,2,3}
docker-compose exec st2node3 st2ctl reload --register-all

# create virtualenvs for all packs on all nodes using st2 action!
# same here, we use st2node1
docker-compose exec st2node1 st2 run core.remote_sudo hosts="st2node1,st2node2,st2node3" cmd="st2ctl reload --register-setup-virtualenvs"

# restart st2sensorcontainer on all nodes as always required when adding new packs
docker-compose exec st2node2 st2 run core.remote_sudo hosts="st2node1,st2node2,st2node3" cmd="st2ctl restart-component st2sensorcontainer"

# setup mistral
docker-compose exec --user postgres postgres psql -c "CREATE ROLE mistral WITH CREATEDB LOGIN ENCRYPTED PASSWORD 'StackStorm';"
docker-compose exec --user postgres postgres psql -c "CREATE DATABASE mistral OWNER mistral;"
docker-compose exec st2node1 /opt/stackstorm/mistral/bin/mistral-db-manage --config-file /etc/mistral/mistral.conf upgrade head
docker-compose exec st2node1 /opt/stackstorm/mistral/bin/mistral-db-manage --config-file /etc/mistral/mistral.conf populate

# restart mistral services on all nodes
docker-compose exec st2node2 st2 run core.remote_sudo hosts="st2node1,st2node2,st2node3" cmd="st2ctl restart-component mistral"

# check status
docker-compose exec st2node2 st2 run core.remote_sudo hosts="st2node1,st2node2,st2node3" cmd="st2ctl status"

# run sample mistral based workflow
docker-compose exec st2node2 st2 run examples.mistral_examples


```

You can also access to HA enabled Web GUI. Check the docker host IP address and just access `https://docker-host-ip` with your favorite browser.

If you are using docker-machine, you can grab your docker host IP with `docker-machine env hoge`
