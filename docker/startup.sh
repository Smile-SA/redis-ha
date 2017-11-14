#!/bin/bash

# Openshift Mode
if [ "$MODE" == "statefulset" ] && [ "$SENTINEL" != "true" ] ; then

    # first statefulset pod is a master
    h=$(hostname)
    if [ $(echo "$h" | grep -o '\-0$') == "-0" ]; then
        echo "Master mode"
        exec "$@"
    fi


    # else it's a slave (sentinel will start, so wait for it)
    CONN=""
    SENTINEL_HOST="127.0.0.1"
    until [ "$CONN" == "ok" ]; do
        echo "wait for sentinel..."
        nc --send-only $SENTINEL_HOST 26379 < /dev/null && CONN="ok" || sleep 1
    done

    CONN=""
    until [ "$CONN" == "ok" ]; do
        master=$(redis-cli -h $SENTINEL_HOST -p 26379 SENTINEL get-master-addr-by-name mymaster | head -n1)
        echo "master is: ${master}, checking..."
        nc --send-only $master 6379 < /dev/null && CONN="ok" || sleep 1
    done

    # let's change the state
    sed -i 's/^slaveof master 6379/slaveof '${master}' 6379/' /etc/redis-slave.conf
    exec redis-server /etc/redis-slave.conf
fi

# else, startup as expected

if [ "$SENTINEL" == "true" ]; then
    echo "Sentinel mode"
    if [ "$MODE" == "statefulset" ]; then
        # we change xxx-1 to xxx-0 that is the master pod
        h=$(hostname -f | sed -r 's/-[0-9]+/-0/')
        sed -i 's/monitor mymaster master/monitor mymaster '$h'/' /etc/redis-sentinel.conf 
        # check that master is up
        CONN=""
        until [ "$CONN" == "ok" ]; do
            nc --send-only $h 6379 < /dev/null && CONN="ok" || sleep 1
        done
    fi

    exec redis-sentinel /etc/redis-sentinel.conf
fi


# this case should not happend in openshift
if [ "$SLAVE" == "true" ]; then
    # if we're on kubernetes/openshift, the sentinel should be running as
    # a container in the same pod. So that sentinel addr is 127.0.0.1
    # But we can provide a sentinel hostname in $SENTINEL_HOST to force
    # in docker-compose for example.
    # Because the initial master will be down, we need to get master address
    # via sentinel

    echo "Slave mode"
    CONN=""
    [ "$SENTINEL_HOST" == "" ] && SENTINEL_HOST="127.0.0.1"
    until [ "$CONN" == "ok" ]; do
        echo "Waiting sentinel ${SENTINEL_HOST}..."
        nc --send-only $SENTINEL_HOST 26379 < /dev/null && CONN="ok" || sleep 1
    done

    CONN=""
    until [ "$CONN" == "ok" ]; do
        master=$(redis-cli -h $SENTINEL_HOST -p 26379 SENTINEL get-master-addr-by-name mymaster | head -n1)
        echo "master is: ${master}, checking..."
        nc --send-only $master 6379 < /dev/null && CONN="ok" || sleep 1
    done

    sed -i 's/^slaveof master 6379/slaveof '${master}' 6379/' /etc/redis-slave.conf
    exec redis-server /etc/redis-slave.conf

fi

exec "$@"
