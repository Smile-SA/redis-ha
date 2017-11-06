#!/bin/bash

if [ "$SENTINEL" == "true" ]; then
    exec redis-sentinel /etc/redis-sentinel.conf
fi

if [ "$SLAVE" == "true" ]; then
    # if we're on kubernetes/openshift, the sentinel should be running as
    # a container in the same pod. So that sentinel addr is 127.0.0.1
    # But we can provide a sentinel hostname in $SENTINEL_HOST to force
    # in docker-compose for example.
    # Because the initial master will be down, we need to get master address
    # via sentinel

    CONN=""
    [ "$SENTINEL_HOST" == "" ] && SENTINEL_HOST="127.0.0.1"
    until [ "$CONN" == "ok" ]; do
        nc --send-only $SENTINEL_HOST 26379 < /dev/null && CONN="ok" || sleep 1
    done

    CONN=""
    until [ "$CONN" == "ok" ]; do
        master=$(redis-cli -h $SENTINEL_HOST -p 26379 SENTINEL get-master-addr-by-name mymaster | head -n1)
        nc --send-only $master 6379 < /dev/null && CONN="ok" || sleep 1
    done

    sed -i 's/^slaveof master 6379/slaveof '${master}' 6379/' /etc/redis-slave.conf
    exec redis-server /etc/redis-slave.conf

fi

exec "$@"
