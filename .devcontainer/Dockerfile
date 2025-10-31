FROM mcr.microsoft.com/devcontainers/base:ubuntu-24.04

ARG NODE_MAJOR=20

ENV DEBIAN_FRONTEND=noninteractive \
    UV_INSTALL_DIR=/usr/local/bin \
    UV_NO_MODIFY_PATH=1 \
    UV_SYSTEM_PYTHON=1 \
    PATH="/usr/local/bin:${PATH}"

WORKDIR /workspace

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        bash-completion \
        build-essential \
        ca-certificates \
        curl \
        docker.io \
        docker-compose-plugin \
        git \
        gnupg \
        less \
        libpq-dev \
        openssh-client \
        postgresql-client \
        python3 \
        python3-dev \
        python3-full \
        python3-pip \
        python3-venv \
        redis-tools \
        unzip \
        vim && \
    rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://deb.nodesource.com/setup_${NODE_MAJOR}.x | bash - && \
    apt-get update && \
    apt-get install -y --no-install-recommends nodejs && \
    corepack enable && \
    npm install -g npm@latest pnpm@9 && \
    rm -rf /var/lib/apt/lists/*

RUN curl -LsSf https://astral.sh/uv/install.sh | bash && \
    ln -sf ${UV_INSTALL_DIR}/uvx /usr/local/bin/uvx && \
    ln -sf ${UV_INSTALL_DIR}/uv /usr/local/bin/uv

RUN curl -sL https://taskfile.dev/install.sh | bash -s -- -d /usr/local/bin && \
    ln -sf /usr/local/bin/task /usr/bin/task

CMD ["/bin/bash"]
