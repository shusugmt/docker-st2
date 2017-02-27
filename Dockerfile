FROM centos:7
MAINTAINER "Shu Sugimoto" <shu@su.gimo.to>

# run yum update first!
# systemd package might be updated and that should come before the tweaks below
RUN yum -y update \
 && yum clean all

# tweaks for running systemd inside container
# see: https://hub.docker.com/_/centos/
ENV container docker
RUN (cd /lib/systemd/system/sysinit.target.wants/; for i in *; do [ $i == systemd-tmpfiles-setup.service ] || rm -f $i; done); \
rm -f /lib/systemd/system/multi-user.target.wants/*;\
rm -f /etc/systemd/system/*.wants/*;\
rm -f /lib/systemd/system/local-fs.target.wants/*; \
rm -f /lib/systemd/system/sockets.target.wants/*udev*; \
rm -f /lib/systemd/system/sockets.target.wants/*initctl*; \
rm -f /lib/systemd/system/basic.target.wants/*;\
rm -f /lib/systemd/system/anaconda.target.wants/*;
VOLUME [ "/sys/fs/cgroup" ]

RUN sed -i '/nodocs/d' /etc/yum.conf

RUN yum -y install sudo \
 && sed -i -r "s/^Defaults\s+\+?requiretty/# Defaults requiretty/g" /etc/sudoers \
 && sed -i -r "s/^Defaults\s+\+?secure_path.*/Defaults !secure_path/g" /etc/sudoers

RUN mkdir -p /tmp/pseudo/bin \
 && ln -s /bin/true /tmp/pseudo/bin/systemctl \
 && ln -s /bin/true /tmp/pseudo/bin/st2ctl \
 && ln -s /bin/true /tmp/pseudo/bin/st2 \
 && ln -s /bin/true /tmp/pseudo/bin/postgresql-setup \
 && ln -s /bin/true /tmp/pseudo/bin/psql \
 && ln -s /bin/true /tmp/pseudo/bin/mistral-db-manage \
 && ln -s /bin/true /tmp/pseudo/bin/mongo \
 && touch /tmp/pseudo/pg_hba.conf

RUN curl -sSL https://raw.githubusercontent.com/StackStorm/st2-packages/master/scripts/st2bootstrap-el7.sh \
  | sed -e 's|/var/lib/pgsql/data/pg_hba.conf|/tmp/pseudo/pg_hba.conf|g' \
  | sed -e 's|/opt/stackstorm/mistral/bin/mistral-db-manage|/tmp/pseudo/bin/mistral-db-manage|g' \
  | PATH=/tmp/pseudo/bin:$PATH bash -s -x -- --user=test --password=changeme --version= \
 && yum -y autoremove mongodb-org rabbitmq-server postgresql-server postgresql-contrib postgresql-devel \
 && yum clean all

RUN rm -rf /tmp/pseudo

RUN bash -c 'source /opt/stackstorm/st2/bin/activate && pip install redis'

RUN yum -y install gcc \
 && yum -y install nfs-utils \
 && yum clean all

RUN cd /etc/nginx/conf.d \
 && curl -sSL -O https://raw.githubusercontent.com/StackStorm/st2/master/conf/HA/nginx/st2.conf.blueprint.sample

RUN rm -f /etc/systemd/system/multi-user.target.wants/*
ADD entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
CMD ["/entrypoint.sh"]

EXPOSE 443
VOLUME ["/opt/stackstorm/packs","/opt/stackstorm/configs","/opt/stackstorm/virtualenvs"]
