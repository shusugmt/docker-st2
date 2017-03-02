#!/bin/bash

set -eux

RELEASE=stable
VERSION=
ST2_PKG=st2
ST2MISTRAL_PKG=st2mistral
ST2WEB_PKG=st2web
ST2CHATOPS_PKG=st2chatops

# copied (partially) from official one-line installation script
# see: https://github.com/StackStorm/st2-packages/blob/master/scripts/st2bootstrap-el7.sh
setup_args() {
  for i in "$@"
    do
      case $i in
          -v|--version=*)
          VERSION="${i#*=}"
          shift
          ;;
          -u|--unstable)
          RELEASE=unstable
          shift
          ;;
          *)
          # unknown option
          ;;
      esac
    done

  if [[ "$VERSION" != '' ]]; then
    if [[ ! "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] && [[ ! "$VERSION" =~ ^[0-9]+\.[0-9]+dev$ ]]; then
      echo "$VERSION does not match supported formats x.y.z or x.ydev"
      exit 1
    fi

    if [[ "$VERSION" =~ ^[0-9]+\.[0-9]+dev$ ]]; then
     echo "You're requesting a dev version! Switching to unstable!"
     RELEASE='unstable'
    fi
  fi
}

# copied (partially) from official one-line installation script
# see: https://github.com/StackStorm/st2-packages/blob/master/scripts/st2bootstrap-el7.sh
get_full_pkg_versions() {
  if [ "$VERSION" != '' ];
  then
    local ST2_VER=$(repoquery --nvr --show-duplicates st2 | grep ${VERSION} | sort --version-sort | tail -n 1)
    if [ -z "$ST2_VER" ]; then
      echo "Could not find requested version of st2!!!"
      sudo repoquery --nvr --show-duplicates st2
      exit 3
    fi
    ST2_PKG=${ST2_VER}

    local ST2MISTRAL_VER=$(repoquery --nvr --show-duplicates st2mistral | grep ${VERSION} | sort --version-sort | tail -n 1)
    if [ -z "$ST2MISTRAL_VER" ]; then
      echo "Could not find requested version of st2mistral!!!"
      sudo repoquery --nvr --show-duplicates st2mistral
      exit 3
    fi
    ST2MISTRAL_PKG=${ST2MISTRAL_VER}

    local ST2WEB_VER=$(repoquery --nvr --show-duplicates st2web | grep ${VERSION} | sort --version-sort | tail -n 1)
    if [ -z "$ST2WEB_VER" ]; then
      echo "Could not find requested version of st2web."
      sudo repoquery --nvr --show-duplicates st2web
      exit 3
    fi
    ST2WEB_PKG=${ST2WEB_VER}

    local ST2CHATOPS_VER=$(repoquery --nvr --show-duplicates st2chatops | grep ${VERSION} | sort --version-sort | tail -n 1)
    if [ -z "$ST2CHATOPS_VER" ]; then
      echo "Could not find requested version of st2chatops."
      sudo repoquery --nvr --show-duplicates st2chatops
      exit 3
    fi
    ST2CHATOPS_PKG=${ST2CHATOPS_VER}

    echo "##########################################################"
    echo "#### Following versions of packages will be installed ####"
    echo "${ST2_PKG}"
    echo "${ST2MISTRAL_PKG}"
    echo "${ST2WEB_PKG}"
    echo "${ST2CHATOPS_PKG}"
    echo "##########################################################"
  fi
}

# parse args
setup_args $@

# install and setup sudo
yum -y install sudo
sed -i -r "s/^Defaults\s+\+?requiretty/# Defaults requiretty/g" /etc/sudoers
sed -i -r "s/^Defaults\s+\+?secure_path.*/Defaults !secure_path/g" /etc/sudoers

# setup epel
yum -y install epel-release
yum-config-manager --disable epel

# install crudini
yum -y --enablerepo=epel install crudini

# configure st2 yum repository based on RELEASE
curl -s https://packagecloud.io/install/repositories/StackStorm/${RELEASE}/script.rpm.sh | bash

# determine which version to install
get_full_pkg_versions

# install st2 core and st2mistral
yum -y install ${ST2_PKG} ${ST2MISTRAL_PKG}

# re-install st2 core package with docs (to get nginx configuration file)
# see: https://github.com/CentOS/sig-cloud-instance-images/issues/21
yum -y --setopt tsflags= reinstall ${ST2_PKG}

# sudo without password for stanley, which is default st2 system account
echo "stanley ALL=(ALL) NOPASSWD: SETENV: ALL" > /etc/sudoers.d/st2

# create default user
yum -y install httpd-tools
echo changeme | sudo htpasswd -i /etc/st2/htpasswd test

# setup simple authentication
sudo crudini --set /etc/st2/st2.conf auth enable True
sudo crudini --set /etc/st2/st2.conf auth backend flat_file
sudo crudini --set /etc/st2/st2.conf auth backend_kwargs '{"file_path": "/etc/st2/htpasswd"}'

# configure credentials using default user
mkdir /root/.st2
crudini --set /root/.st2/config credentials username test
crudini --set /root/.st2/config credentials password changeme

# install redis support to enable st2 policing
# see: https://docs.stackstorm.com/latest/reference/policies.html
bash -c 'source /opt/stackstorm/st2/bin/activate && pip install redis'

# required for: st2ctl reload --register-setup-virtualenvs
yum -y install gcc

# setup nginx repo for st2web
cat << EOF > /etc/yum.repos.d/nginx.repo
[nginx]
name=nginx repo
baseurl=http://nginx.org/packages/centos/\$releasever/\$basearch/
gpgcheck=0
enabled=1
EOF

# install st2web, nginx
# it is rather safe to disable epel because nginx package is also in there
yum -y install ${ST2WEB_PKG} nginx

# copy st2web config
cp /usr/share/doc/st2/conf/nginx/st2.conf /etc/nginx/conf.d/

# create self-signed cert for https
mkdir -p /etc/ssl/st2
sudo openssl req -x509 -newkey rsa:2048 -keyout /etc/ssl/st2/st2.key -out /etc/ssl/st2/st2.crt -days 3650 -nodes -subj '/O=st2 self signed/CN=localhost'

# setup nodejs repo for st2chatops
curl -sL https://rpm.nodesource.com/setup_4.x | sudo -E bash -

# install st2chatops (and nodejs)
# need to disable epel because newer version of nodejs is there
yum -y install ${ST2CHATOPS_PKG}

# for HA setup
yum -y install nfs-utils
cd /etc/nginx/conf.d && curl -sSL -O https://raw.githubusercontent.com/StackStorm/st2/master/conf/HA/nginx/st2.conf.blueprint.sample

# cleanup
yum --enablerepo=* clean all

