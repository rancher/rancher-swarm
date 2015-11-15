#!/bin/bash
set -e

#apt-get install -y gcc

go get github.com/tools/godep
cd $GOPATH/src 
mkdir -p github.com/docker 
mkdir -p github.com/rancher

cd $GOPATH/src/github.com/rancher 
git clone https://github.com/rancher/os.git 
cd os 
git checkout v0.4.0

cd $GOPATH/src/github.com/docker 
git clone https://github.com/docker/swarm.git 
cd swarm 
git checkout v1.0.0

cd $GOPATH/src/github.com/docker/swarm 
godep go build -o /usr/bin/swarm main.go

cat << EOF > $GOPATH/src/github.com/rancher/os/ros.go
package main
import "github.com/rancher/os/cmd/control"
func main() { control.Main() }
EOF

cd $GOPATH/src/github.com/rancher/os 
godep go build -o /usr/bin/ros ros.go

mkdir -p /var/lib/rancher/conf/cloud-config.d

go get -d github.com/rancher/rancher-docker-api-proxy
cd $GOPATH/src/github.com/rancher/rancher-docker-api-proxy 
go build -o /usr/bin/proxy main/main.go

go get github.com/rancher/leader

#apt-get purge -y gcc
#apt-get autoremove -y
#apt-get autoclean -y
