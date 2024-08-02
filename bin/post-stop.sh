#!/bin/bash
export XDG_RUNTIME_DIR=/run/user/$UID
export DOCKER_HOST=unix:///run/user/1001/docker.sock

docker stop github-runner || echo ok
docker stop dind-rootless || echo ok

sleep 5

docker volume rm dindHome
docker volume rm dockerSock
docker volume rm dindWork
docker volume rm dindRunner
docker volume rm dindToolsCache

rm -rf /home/github-runner/dind-etc
rm -f /home/github-runner/runner-decrypted.env
rm -f /home/github-runner/runner-decrypted-private-key.pem