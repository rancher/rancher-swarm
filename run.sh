#!/bin/bash
set -e

export PID=$$
HOSTS=rancher-metadata/latest/hosts

cert_args()
{
    local args=""
    for i in $(curl -s -H 'Accept: application/json' 169.254.169.250/latest/hosts | jq -r '[.[].name]|sort|.[]'); do
        args="${args} --hostname=$i"
    done

    echo $args
}

hosts()
{
    PORT=3000
    ARGS=()
    for i in $(curl -s -H 'Accept: application/json' 169.254.169.250/latest/hosts | jq -r '[.[].name]|sort|.[]'); do
        CERT_ARGS="$CERT_ARGS --hostname=$i"
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

if [ ! -e server-key.pem ]; then
    ros tls generate --hostname=localhost --hostname=127.0.0.1 --hostname=0.0.0.0 --hostname=/var/run/docker.sock $(cert_args) -s -d $(pwd)
fi

if [ ! -e key.pem ]; then
    cp server-key.pem key.pem
fi

if [ ! -e cert.pem ]; then
    cp server-cert.pem cert.pem
fi

watch &
(
    proxy $(hosts) || kill $PID
) &

if [ ! -e ${HOME}/.docker ]; then
    ln -s $(pwd) ${HOME}/.docker
fi

ping_nodes

exec swarm manage --tlscacert=ca.pem --tlscert=cert.pem --tlskey=key.pem --tlsverify -H tcp://0.0.0.0:2376 -H unix:///var/run/docker.sock $(swarm_node)
