FROM ubuntu:latest

WORKDIR /app

# Copy the current directory into the container at /app
COPY . /app

# Install necessary packages
RUN apt-get update && apt-get install -y \
    # Mach build tools
    build-essential make msitools wget unzip rustc \
    # Python
    python3 python3-dev python3-pip \
    # Camoufox build system tools
    git p7zip-full golang-go aria2 curl rsync \
    # Platform-specific libraries for Linux builds
    libsqlite3-dev \
    # CA certificates
    ca-certificates \
    && update-ca-certificates

# Compare verified file SHA256 against incoming rustup file, then execute file contents
# RUN curl https://sh.rustup.rs -sSf | bash -s -- -y
ARG RUSTUP_VERSION=1.29.0
ARG RUSTUP_INIT_SHA256="4acc9acc76d5079515b46346a485974457b5a79893cfb01112423c89aeb5aa10"

RUN curl --proto '=https' --tlsv1.2 \
      --fail --show-error --location \
      "https://static.rust-lang.org/rustup/archive/${RUSTUP_VERSION}/x86_64-unknown-linux-gnu/rustup-init" \
      --output /tmp/rustup-init \
    && echo "${RUSTUP_INIT_SHA256}  /tmp/rustup-init" \
      | sha256sum --check --strict \
    && chmod +x /tmp/rustup-init \
    && /tmp/rustup-init \
      -y \
      --profile minimal \
      --default-toolchain 1.97.1 \
      --no-modify-path \
    && rm /tmp/rustup-init

ENV PATH="/root/.cargo/bin:${PATH}"

# Fetch Firefox & apply initial patches
RUN make setup-minimal && \
    make mozbootstrap && \
    mkdir -p /app/dist

# Mount .mozbuild directory and dist folder
VOLUME /root/.mozbuild
VOLUME /app/dist

ENTRYPOINT ["python3", "./multibuild.py"]
