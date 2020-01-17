#!/bin/sh

export IIOS_DLAKE_VERSION=3.4.0
export IIOS_AUTH_VERSION=1.2.0

docker network create --opt encrypted -d overlay infra
docker stack deploy -c swarm/docker-compose.yml chaman
