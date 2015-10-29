#!/bin/bash
set -e

export PID=$$
HOSTS=rancher-metadata/latest/hosts

hosts()
{
    PORT=3000
    ARGS=()
    for i in $(curl -s -H 'Accept: application/json' 169.254.169.250/latest/hosts | jq -r '[.[].name]|sort|.[]'); do
        ARGS+=($i tcp://localhost:$PORT)
        PORT=$((PORT+1))
    done
    
    echo ${ARGS[@]}
}

ping_nodes()
{
    for i in $(hosts); do
        case $i in
            tcp:*)
                echo -n Contacting $name $i
                while ! docker -H $i info >/dev/null 2>&1; do
                    sleep 1
                done
                echo " OK"
                ;;
            *)
                local name=$1
                ;;
        esac
    done
}

swarm_node()
{
    local node=""
    for i in $(hosts); do
        case $i in
            tcp:*)
                if [ "$node" = "" ]; then
                    node=${i##tcp://}
                else
                    node="$node,${i##tcp://}"
                fi
                ;;
        esac
    done

    echo "nodes://$node"
}

watch()
{
    local val="$(hosts)"
    while sleep 5; do
        if [ "$val" != "$(hosts)" ]; then
            kill $PID
        fi
    done
}

while ! curl -s $HOSTS; do
    sleep .5
done

# TODO: enable TLS
#ros tls generate --hostname=localhost --hostname=127.0.0.1 -s -d $(pwd)
#if [ ! -e key.pem ]; then
#    ros tls generate --hostname=localhost --hostname=127.0.0.1 -d $(pwd)
#fi

watch &
(
    proxy $(hosts) || kill $PID
) &

ping_nodes

# TODO: TLS is broken right now because I need to generate certs that work as both server and client... sigh...
#exec swarm manage --tlscacert=ca.pem --tlscert=cert.pem --tlskey=key.pem --tlsverify -H tcp://0.0.0.0:2376 -H unix:///var/run/docker.sock $(swarm_node)
exec swarm manage -H tcp://0.0.0.0:2375 -H unix:///var/run/docker.sock $(swarm_node)
