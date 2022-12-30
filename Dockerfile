FROM api7/apisix-base:dev AS build

ARG ENABLE_PROXY=false
ARG APISIX_VERSION=release/2.13

ENV DEBIAN_FRONTEND noninteractive

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

# get codes
RUN git clone https://github.com/api7/apisix-plugin-template.git \
    && cd apisix-plugin-template \
    && sudo sed -i "s@release/2.12@${APISIX_VERSION}@" ci/utils/linux-common-runnner.sh \
    && make init_apisix \
    && make patch_apisix \
    && cd workbench \
    && git clone https://github.com/openresty/test-nginx.git test-nginx \
    && make utils \
    && cd ../ \
    && mv ./workbench /opt/apisix \
    && cd /opt/apisix \
    && rm -rf /opt/apisix-plugin-template

# install etcd
RUN wget -O etcd-v3.5.6-linux-amd64.tar.gz https://github.com/etcd-io/etcd/releases/download/v3.5.6/etcd-v3.5.6-linux-amd64.tar.gz && \
    tar -xvf etcd-v3.5.6-linux-amd64.tar.gz && \
    cd etcd-v3.5.6-linux-amd64 && \
    cp -a etcd etcdctl /usr/bin/ && \
    rm -rf /opt/etcd-*

# refresh project codes
COPY ./docker-entrypoint.sh /docker-entrypoint.sh

ENTRYPOINT ["/docker-entrypoint.sh"]

CMD ["/bin/bash"]
