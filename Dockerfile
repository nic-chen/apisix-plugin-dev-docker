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
    && apt-get install -y ca-certificates gnupg cpanminus lsb-release build-essential libncurses5-dev libreadline-dev libssl-dev perl libpcre3 libpcre3-dev \
    && sudo ln -s /lib/x86_64-linux-gnu/libpcre.so.3 /usr/lib/libpcre.so \
    && cpanm --notest Test::Nginx > build.log 2>&1 || (cat build.log && exit 1) \
    && curl https://raw.githubusercontent.com/apache/apisix/master/utils/install-dependencies.sh -sL | bash - \
    && mkdir -p /etc/apt/keyrings \
    && curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null \
    && apt-get update \
    && apt-get install -y docker-ce docker-ce-cli containerd.io \
    && apt-get remove --purge --auto-remove -y \
    && rm -rf /var/lib/apt/lists/*

# install etcd
RUN wget -O etcd-v3.5.6-linux-amd64.tar.gz https://github.com/etcd-io/etcd/releases/download/v3.5.6/etcd-v3.5.6-linux-amd64.tar.gz && \
    tar -xvf etcd-v3.5.6-linux-amd64.tar.gz && \
    cd etcd-v3.5.6-linux-amd64 && \
    cp -a etcd etcdctl /usr/bin/ && \
    rm -rf /opt/etcd-*

# install docker-compose
RUN curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose \
    && chmod +x /usr/local/bin/docker-compose

COPY ./docker-entrypoint.sh /docker-entrypoint.sh

ENTRYPOINT ["/docker-entrypoint.sh"]

CMD ["/bin/bash"]
