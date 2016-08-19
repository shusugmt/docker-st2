FROM centos:7
MAINTAINER "Shu Sugimoto" <shu@su.gimo.to>

# run yum update first!
# systemd package might be updated and that should come before the tweaks below
RUN yum -y update

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
CMD ["/usr/sbin/init"]

RUN yum -y install nfs-utils && yum clean all
RUN echo '/data *(rw,all_squash,fsid=0)' > /etc/exports
RUN mkdir -p /data/packs
RUN mkdir -p /data/configs

RUN yum -y install unzip \
 && curl -sSL -O https://github.com/StackStorm/st2/archive/master.zip \
 && unzip master.zip \
 && cp -a st2-master/contrib/* /data/packs \
 && rm -Rf master.zip st2-master \
 && yum -y autoremove unzip \
 && yum clean all

RUN chown -Rf nfsnobody: /data
VOLUME [ "/data" ]

RUN rm -f /etc/systemd/system/multi-user.target.wants/*
RUN systemctl enable rpcbind
RUN systemctl enable nfs-server
