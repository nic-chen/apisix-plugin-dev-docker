FROM api7/apisix-base:dev AS build

ARG ENABLE_PROXY=false
ARG APISIX_VERSION=release/2.13
ARG TARGETPLATFORM=x86_64
ARG DOCKER_CHANNEL=stable
ARG DOCKER_VERSION=20.10.8

ENV DEBIAN_FRONTEND noninteractive
ENV TEST_NGINX_BINARY=/usr/local/openresty-debug/bin/openresty

WORKDIR /opt

RUN set -x \
    && (test "${ENABLE_PROXY}" != "true" || /bin/sed -i 's,http://deb.debian.org,http://mirrors.aliyun.com,g' /etc/apt/sources.list) \
    && apt-get -y update --fix-missing \
    && apt-get install -y curl gawk git libldap2-dev liblua5.1-0-dev lua5.1 make sudo unzip wget procps software-properties-common \
    && apt-get install -y cpanminus lsb-release build-essential libncurses5-dev libreadline-dev libssl-dev perl libpcre3 libpcre3-dev \
    && sudo ln -s /lib/x86_64-linux-gnu/libpcre.so.3 /usr/lib/libpcre.so \
    && cpanm --notest Test::Nginx > build.log 2>&1 || (cat build.log && exit 1) \
    && apt-get remove --purge --auto-remove -y \
    && curl https://raw.githubusercontent.com/apache/apisix/master/utils/install-dependencies.sh -sL | bash -

# install etcd
RUN wget -O etcd-v3.5.6-linux-amd64.tar.gz https://github.com/etcd-io/etcd/releases/download/v3.5.6/etcd-v3.5.6-linux-amd64.tar.gz && \
    tar -xvf etcd-v3.5.6-linux-amd64.tar.gz && \
    cd etcd-v3.5.6-linux-amd64 && \
    cp -a etcd etcdctl /usr/bin/ && \
    rm -rf /opt/etcd-*

# install docker-compose
RUN curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose \
    && chmod +x /usr/local/bin/docker-compose

# https://download.docker.com/linux/static///docker-.tgz
# install docker
RUN set -vx; \
    export ARCH=$(echo ${TARGETPLATFORM} | cut -d / -f2) \
    && if [ "$ARCH" = "arm64" ]; then export ARCH=aarch64 ; fi \
    && if [ "$ARCH" = "amd64" ] || [ "$ARCH" = "i386" ]; then export ARCH=x86_64 ; fi \
    && curl -f -L -o docker.tgz https://download.docker.com/linux/static/${DOCKER_CHANNEL}/${ARCH}/docker-${DOCKER_VERSION}.tgz \
    && tar zxvf docker.tgz \
    && install -o root -g root -m 755 docker/docker /usr/local/bin/docker \
    && rm -rf docker docker.tgz \
    && adduser --disabled-password --gecos "" --uid 1000 runner \
    && groupadd docker \
    && usermod -aG sudo runner \
    && usermod -aG docker runner \
    && echo "%sudo   ALL=(ALL:ALL) NOPASSWD:ALL" > /etc/sudoers

COPY ./docker-entrypoint.sh /docker-entrypoint.sh

ENTRYPOINT ["/docker-entrypoint.sh"]

CMD ["/bin/bash"]
