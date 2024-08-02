# github-runner-docker-ephemeral

Here are collected scripts that allow to run github-runner in a docker container with rootless dind.

Prepare the github-runner user:

```bash
sudo groupadd github-runner -g 1001
sudo useradd github-runner -u 1001 -g 1001 -s /bin/bash -m
sudo apt update
sudo apt install -y uidmap jq
# https://unix.stackexchange.com/questions/587674/systemd-not-detected-dockerd-daemon-needs-to-be-started-manually
sudo loginctl enable-linger github-runner
sudo su github-runner
export XDG_RUNTIME_DIR=/run/user/$UID
dockerd-rootless-setuptool.sh install
```

Create `/home/github-runner/bin` folder and copy files from bin.  
Create `/home/github-runner/runner.env` file with your settings. Scripts are working only with `app_id` and `app_private_key`.  

Move `runner.service` to `/home/github-runner/.config/systemd/user` and enable the service:

```bash
mv runner.service /home/github-runner/.config/systemd/user/runner.service
systemctl --user enable runner
systemctl --user start runner
```

