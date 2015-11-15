#!/bin/bash
set -e

docker build -t test .
docker run --rm -l io.rancher.container.network=true -l io.rancher.container.dns=true -e CATTLE_URL=http://localhost:8080/v1/projects/1a5/schemas --net=host -it test bash
