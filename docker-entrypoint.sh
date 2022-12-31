#!/bin/bash
nohup etcd > /tmp/etcd.log 2>&1 &
ps aux | grep etcd | grep etcd 

if pgrep etcd > /dev/null;then
    echo "ETCD Start success"
fi

exec "$@"
