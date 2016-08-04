FROM centos:7
MAINTAINER "Shu Sugimoto" <shu@su.gimo.to>
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
CMD ["/usr/sbin/init"]

RUN yum -y update

RUN sed -i '/nodocs/d' /etc/yum.conf

RUN yum -y install sudo
RUN sed -i -r "s/^Defaults\s+\+?requiretty/# Defaults requiretty/g" /etc/sudoers
RUN sed -i -r "s/^Defaults\s+\+?secure_path.*/Defaults !secure_path/g" /etc/sudoers
RUN cat /etc/sudoers

RUN mkdir -p /tmp/pseudo/bin
RUN ln -s /bin/true /tmp/pseudo/bin/systemctl
RUN ln -s /bin/true /tmp/pseudo/bin/st2ctl
RUN ln -s /bin/true /tmp/pseudo/bin/st2
RUN ln -s /bin/true /tmp/pseudo/bin/postgresql-setup
RUN ln -s /bin/true /tmp/pseudo/bin/psql
RUN ln -s /bin/true /tmp/pseudo/bin/mistral-db-manage
RUN touch /tmp/pseudo/pg_hba.conf

RUN curl -sSL https://raw.githubusercontent.com/StackStorm/st2-packages/master/scripts/st2bootstrap-el7.sh \
  | sed -e 's|/var/lib/pgsql/data/pg_hba.conf|/tmp/pseudo/pg_hba.conf|g' \
  | sed -e 's|/opt/stackstorm/mistral/bin/mistral-db-manage|/tmp/pseudo/bin/mistral-db-manage|g' \
  | PATH=/tmp/pseudo/bin:$PATH bash -s -x -- --user=test --password=changeme --version=1.5.1

RUN rm -rf /tmp/pseudo

RUN systemctl enable nginx

RUN yum -y autoremove mongodb-org rabbitmq-server postgresql-server postgresql-contrib postgresql-devel
RUN yum clean all

RUN crudini --set /etc/st2/st2.conf database host 'mongo'
RUN crudini --set /etc/st2/st2.conf messaging url 'amqp://guest:guest@rabbitmq:5672/'
RUN crudini --set /etc/mistral/mistral.conf DEFAULT transport_url 'rabbit://guest:guest@rabbitmq:5672'
RUN crudini --set /etc/mistral/mistral.conf database connection 'postgresql://mistral:StackStorm@postgres/mistral'

EXPOSE 443
