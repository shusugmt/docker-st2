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

ADD build_image.sh /root/build_image.sh
RUN chmod +x /root/build_image.sh
RUN /root/build_image.sh --unstable

RUN rm -f /etc/systemd/system/multi-user.target.wants/*

ADD entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
CMD ["/entrypoint.sh"]

EXPOSE 443
VOLUME ["/opt/stackstorm/packs","/opt/stackstorm/configs","/opt/stackstorm/virtualenvs"]
