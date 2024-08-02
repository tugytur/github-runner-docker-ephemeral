#!/bin/bash

# scripts and runner will use runner-decrypted.env
cp /home/github-runner/runner.env /home/github-runner/runner-decrypted.env
# move the private key to a separate file
cat /home/github-runner/runner.env | grep APP_PRIVATE_KEY | sed 's/APP_PRIVATE_KEY=//g' | sed 's/\\n/\'$'\n''/g' > /home/github-runner/runner-decrypted-private-key.pem
# remove the private key from the runner-decrypted.env
sed -i '/APP_PRIVATE_KEY/d' /home/github-runner/runner-decrypted.env
# generate short-lived token
export $(cat /home/github-runner/runner-decrypted.env)
ACCESS_TOKEN=$(APP_ID="${APP_ID}" REPO_URL="${REPO_URL}" bash /home/github-runner/bin/get_token.sh)
_TOKEN=$(ACCESS_TOKEN="${ACCESS_TOKEN}" bash /home/github-runner/bin/get_runner_token.sh)
echo "RUNNER_TOKEN=$(echo "${_TOKEN}" | jq -r .token)" >> /home/github-runner/runner-decrypted.env
echo "RUNNER_NAME=$(hostname)" >> /home/github-runner/runner-decrypted.env
# remove the APP_ID from the runner-decrypted.env
sed -i '/APP_ID/d' /home/github-runner/runner-decrypted.env
unset APP_ID

# prepare docker in docker environment before starting the runner

export XDG_RUNTIME_DIR=/run/user/$UID
export DOCKER_HOST=unix:///run/user/1001/docker.sock

mkdir -p /home/github-runner/dind-etc
docker run --rm --name dind-prepare -exec docker:25.0.5-dind-rootless cat /etc/subuid > /home/github-runner/dind-etc/subuid
docker run --rm --name dind-prepare -exec docker:25.0.5-dind-rootless cat /etc/subgid > /home/github-runner/dind-etc/subgid
docker run --rm --name dind-prepare -exec docker:25.0.5-dind-rootless cat /etc/group > /home/github-runner/dind-etc/group
docker run --rm --name dind-prepare -exec docker:25.0.5-dind-rootless cat /etc/passwd > /home/github-runner/dind-etc/passwd

echo 'runner:x:1001:1001:runner:/home/runner:/bin/bash' >> /home/github-runner/dind-etc/passwd
echo 'runner:x:1001:' >> /home/github-runner/dind-etc/group
echo 'runner:100000:65536' >> /home/github-runner/dind-etc/subgid
echo 'runner:100000:65536' >>  /home/github-runner/dind-etc/subuid

docker volume create --name dindHome
docker volume create --name dockerSock
docker volume create --name dindWork
docker volume create --name dindRunner
docker volume create --name dindToolsCache

docker run --rm --name dind-prepare -exec -v dindHome:/home debian:12-slim bash -c "mkdir /home/runner; chown -R 1001:1001 /home/runner"
docker run --rm --name dind-prepare -exec -v dockerSock:/run/docker debian:12-slim bash -c "cd /run; chmod 777 docker"

docker run -d --rm --name dind-rootless \
  --privileged \
  -exec \
  -v dockerSock:/run/docker \
  -v /home/github-runner/dind-etc/subuid:/etc/subuid \
  -v /home/github-runner/dind-etc/subgid:/etc/subgid \
  -v /home/github-runner/dind-etc/passwd:/etc/passwd \
  -v /home/github-runner/dind-etc/group:/etc/group \
  -v dindHome:/home \
  -v dindWork:/_work \
  -v dindRunner:/actions-runner \
  -v dindToolsCache:/opt/hostedtoolcache \
  docker:27.0.2-dind sh -c "dockerd --host=unix:///run/docker/docker.sock"
  # remove previous line and uncomment the following line to use fuse-overlayfs
  # docker:27.0.2-dind sh -c "apk update; apk add fuse-overlayfs; dockerd -s fuse-overlayfs --host=unix:///run/docker/docker.sock"

sleep 3

docker run --rm --name dind-prepare -exec -v dockerSock:/run/docker debian:12-slim bash -c "cd /run/docker; chmod 666 docker.sock"
