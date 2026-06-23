#!/bin/bash
set -euo pipefail

REPO=$REPO
NAME=${NAME:-$(hostname)}

# --- Clean up any stale docker state from a prior run ---
sudo rm -f /var/run/docker.pid

# --- Start Docker daemon ---
sudo dockerd > /var/log/dockerd.log 2>&1 &

# Wait for Docker, but don't loop forever
for i in $(seq 1 30); do
    if docker info >/dev/null 2>&1; then
        echo "Docker daemon is running"
        break
    fi
    echo "Waiting for Docker daemon... ($i)"
    sleep 1
    if [ "$i" -eq 30 ]; then
        echo "Docker daemon failed to start"; cat /var/log/dockerd.log; exit 1
    fi
done

cd /home/runner/actions-runner || exit 1

# --- Always get a FRESH registration token at runtime via the API ---
# Requires ACCESS_TOKEN (a PAT or GitHub App token with repo/admin scope)
get_token() {
  curl -sX POST \
    -H "Authorization: Bearer ${ACCESS_TOKEN}" \
    -H "Accept: application/vnd.github+json" \
    "https://api.github.com/repos/${REPO}/actions/runners/registration-token" \
    | jq -r .token
}

REG_TOKEN=$(get_token)

# --- Remove stale config if present, then configure fresh, ephemeral ---
if [ -f .runner ]; then
    ./config.sh remove --token "${REG_TOKEN}" || true
    REG_TOKEN=$(get_token)   # remove may consume the token
fi

./config.sh \
    --url "https://github.com/${REPO}" \
    --token "${REG_TOKEN}" \
    --name "${NAME}" \
    --ephemeral \
    --unattended \
    --replace

cleanup() {
  echo "Removing runner..."
  ./config.sh remove --token "$(get_token)" || true
}
trap 'cleanup; exit 130' INT
trap 'cleanup; exit 143' TERM

./run.sh & wait $!
