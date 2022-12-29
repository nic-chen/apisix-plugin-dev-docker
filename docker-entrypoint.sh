#!/bin/bash
nohup etcd > /tmp/etcd.log 2>&1 &
ps aux | grep etcd | grep etcd 

if pgrep etcd > /dev/null;then
    echo "ETCD Start success"
fi

if [[ not -d /opt/custom-project ]];then
else
    mkdir -p /opt/custom-project
fi

cp -r /opt/custom-project/. /opt/apisix


echo "Found apisix source code in /opt/apisix, make init, Plz Wait..."
cd /opt/apisix \
&& make deps \
&& make init \
&& printf "
init success.

current you can:

run \`prove -I/opt/test-nginx/lib -r /opt/apisix/t/plugin/<xxx.t>\` to run a specified test case;
run \`prove -I/opt/test-nginx/lib -r /opt/apisix/t .\` to run all test case
"

exec "$@"
