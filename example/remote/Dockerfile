FROM centos:7
MAINTAINER "Shu Sugimoto" <shu@su.gimo.to>

RUN yum -y install sudo openssh-server
RUN ssh-keygen -t rsa -f /etc/ssh/ssh_host_rsa_key -N '' 
RUN mkdir /var/run/sshd

RUN useradd stanley
RUN mkdir -p /home/stanley/.ssh
RUN chmod 0700 /home/stanley/.ssh
RUN ssh-keygen -f /home/stanley/.ssh/stanley_rsa -P ""
RUN cat /home/stanley/.ssh/stanley_rsa.pub >> /home/stanley/.ssh/authorized_keys
RUN chmod 0600 /home/stanley/.ssh/authorized_keys
RUN chown -R stanley:stanley /home/stanley
RUN echo "stanley    ALL=(ALL)       NOPASSWD: SETENV: ALL" >> /etc/sudoers.d/st2
RUN chmod 0440 /etc/sudoers.d/st2
RUN sed -i -r "s/^Defaults\s+\+?requiretty/# Defaults requiretty/g" /etc/sudoers

RUN yum clean all

EXPOSE 22
ENTRYPOINT ["/usr/sbin/sshd", "-D"]
