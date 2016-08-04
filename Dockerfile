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

RUN sed -i '/nodocs/d' /etc/yum.conf

RUN yum -y install sudo

RUN yum -y install yum-utils
RUN curl -sL https://packagecloud.io/install/repositories/StackStorm/stable/script.rpm.sh | bash

RUN yum -y install epel-release

RUN yum -y install st2

RUN mkdir -p /home/stanley/.ssh
RUN chmod 0700 /home/stanley/.ssh
RUN ssh-keygen -f /home/stanley/.ssh/stanley_rsa -P ""
RUN cat /home/stanley/.ssh/stanley_rsa.pub >> /home/stanley/.ssh/authorized_keys
RUN chmod 0600 /home/stanley/.ssh/authorized_keys
RUN chown -R stanley:stanley /home/stanley
RUN echo "stanley    ALL=(ALL)       NOPASSWD: SETENV: ALL" >> /etc/sudoers.d/st2
RUN chmod 0440 /etc/sudoers.d/st2
RUN sed -i -r "s/^Defaults\s+\+?requiretty/# Defaults requiretty/g" /etc/sudoers

RUN yum -y install httpd-tools crudini
RUN echo changeme | htpasswd -i /etc/st2/htpasswd test
RUN crudini --set /etc/st2/st2.conf auth enable 'True'
RUN crudini --set /etc/st2/st2.conf auth backend 'flat_file'
RUN crudini --set /etc/st2/st2.conf auth backend_kwargs '{"file_path": "/etc/st2/htpasswd"}'

RUN mkdir /root/.st2
RUN crudini --set /root/.st2/config credentials username 'test'
RUN crudini --set /root/.st2/config credentials password 'changeme'

RUN yum -y install st2mistral

RUN rpm -i http://nginx.org/packages/centos/7/noarch/RPMS/nginx-release-centos-7-0.el7.ngx.noarch.rpm
RUN yum -y install st2web nginx
RUN mkdir -p /etc/ssl/st2
RUN openssl req -x509 -newkey rsa:2048 -keyout /etc/ssl/st2/st2.key -out /etc/ssl/st2/st2.crt -days 3650 -nodes -subj "/CN=stackstorm"
RUN cp /usr/share/doc/st2/conf/nginx/st2.conf /etc/nginx/conf.d/
RUN sed -i 's/default_server//g' /etc/nginx/nginx.conf
RUN systemctl enable nginx

RUN curl -sL https://rpm.nodesource.com/setup_4.x | bash
RUN yum -y install nodejs
RUN yum -y install st2chatops

RUN crudini --set /etc/st2/st2.conf database host 'mongo'
RUN crudini --set /etc/st2/st2.conf messaging url 'amqp://guest:guest@rabbitmq:5672/'
RUN crudini --set /etc/mistral/mistral.conf DEFAULT transport_url 'rabbit://guest:guest@rabbitmq:5672'
RUN crudini --set /etc/mistral/mistral.conf database connection 'postgresql://mistral:StackStorm@postgres/mistral'

RUN rpm -qa | grep st2

RUN yum clean all

EXPOSE 443
