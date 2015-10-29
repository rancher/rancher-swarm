FROM golang:1.4.3
RUN go get github.com/tools/godep
RUN cd $GOPATH/src && \
    mkdir -p github.com/docker && \
    mkdir -p github.com/rancher

RUN cd $GOPATH/src/github.com/rancher && \
    git clone https://github.com/rancher/os.git && \
    cd os && \
    git checkout v0.4.0

RUN cd $GOPATH/src/github.com/docker && \
    git clone https://github.com/docker/swarm.git && \
    cd swarm && \
    git checkout v0.4.0

RUN cd $GOPATH/src/github.com/docker/swarm && \
find -type f && \
    godep go build -o /usr/bin/swarm main.go

RUN apt-get update && apt-get install -y libblkid-dev libmount-dev libselinux1-dev jq
COPY ros.go $GOPATH/src/github.com/rancher/os/
RUN cd $GOPATH/src/github.com/rancher/os && \
    godep go build -o /usr/bin/ros ros.go

RUN mkdir -p /var/lib/rancher/conf/cloud-config.d

RUN go get -d github.com/rancher/rancher-docker-api-proxy
RUN cd $GOPATH/src/github.com/rancher/rancher-docker-api-proxy && \
    git remote add gh https://github.com/ibuildthecloud/rancher-docker-api-proxy.git && \
    git fetch gh && \
    git checkout gh/master && \
    go build -o /usr/bin/proxy main/main.go

RUN curl -L https://github.com/docker/compose/releases/download/1.4.2/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose && \
    chmod +x /usr/local/bin/docker-compose

RUN curl -L https://get.docker.com/builds/Linux/x86_64/docker-1.7.1 > /usr/bin/docker && \
    chmod +x /usr/bin/docker

COPY run.sh /usr/bin/
WORKDIR /var/lib/rancher/conf
CMD ["/usr/bin/run.sh"]
EXPOSE 2375
