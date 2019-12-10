#!/bin/sh

helm template -n chaman \
  --values ./values/redis-ha.yaml \
  --output-dir ./manifests \
    ./charts/redis-ha
