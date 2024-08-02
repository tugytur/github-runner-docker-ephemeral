#!/bin/bash
export XDG_RUNTIME_DIR=/run/user/$UID
export DOCKER_HOST=unix:///run/user/1001/docker.sock

docker run --rm --name github-runner \
  --privileged \
  --env-file /home/github-runner/runner-decrypted.env \
  -v dockerSock:/run/docker \
  -v dindHome:/home \
  -v dindWork:/_work \
  -v dindRunner:/actions-runner \
  -v dindToolsCache:/opt/hostedtoolcache \
  myoung34/github-runner:latest
