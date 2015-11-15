FROM ubuntu:15.10
ENV GO_VERSION 1.4.3
ENV GOPATH /go
ENV PATH $PATH:/usr/local/go/bin
RUN apt-get update && \
    apt-get install -y jq curl && \
    apt-get install -y libblkid-dev libmount-dev libselinux1-dev git && \
    curl -L https://storage.googleapis.com/golang/go1.4.3.linux-amd64.tar.gz | tar xvzf - -C /usr/local
RUN apt-get install -y gcc
RUN curl -L https://get.docker.com/builds/Linux/x86_64/docker-1.8.3 > /usr/bin/docker
RUN chmod +x /usr/bin/docker

ENV PATH $PATH:/usr/local/go/bin:$GOPATH/bin

COPY setup.sh /usr/bin/
RUN /usr/bin/setup.sh
COPY run.sh /usr/bin/

ENV DOCKER_TLS_VERIFY 1
ENV DOCKER_HOST tcp://localhost:2376
WORKDIR /var/lib/rancher/conf
ENTRYPOINT ["leader", "--proxy-tcp-port", "2376"]
CMD ["/usr/bin/run.sh"]
EXPOSE 2376
