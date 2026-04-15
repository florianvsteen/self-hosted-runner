#!/bin/bash
REPO=$REPO
REG_TOKEN=$REG_TOKEN
NAME=$NAME

# Start Docker daemon
sudo dockerd &

# Wait for Docker to be ready
until docker info >/dev/null 2>&1; do
    echo "Waiting for Docker daemon..."
    sleep 1
done
echo "Docker daemon is running"

cd /home/docker/actions-runner || exit
./config.sh --url https://github.com/${REPO} --token ${REG_TOKEN} --name ${NAME}

cleanup() {
  echo "Removing runner..."
  ./config.sh remove --unattended --token ${REG_TOKEN}
}

trap 'cleanup; exit 130' INT
trap 'cleanup; exit 143' TERM

./run.sh & wait $!
