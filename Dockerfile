FROM ubuntu:24.04
ARG RUNNER_VERSION="2.331.0"
ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update -y && apt-get upgrade -y && apt-get install -y --no-install-recommends \
    curl \
    build-essential \
    libssl-dev \
    libffi-dev \
    python3 \
    python3-venv \
    python3-dev \
    python3-pip \
    jq \
    unzip \
    zip \
    ssh \
    git \
    sudo \
    wget \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN useradd -m docker && usermod -aG sudo docker \
    && echo "docker ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

RUN cd /home/docker && mkdir actions-runner && cd actions-runner \
    && curl -o actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz -L https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz \
    && tar xzf actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz \
    && rm actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz

RUN chown -R docker /home/docker && /home/docker/actions-runner/bin/installdependencies.sh

COPY --chmod=+x start.sh /start.sh

USER docker

ENTRYPOINT ["/start.sh"]
