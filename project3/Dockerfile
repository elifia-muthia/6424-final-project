FROM golang:1.21-bullseye AS tdx_builder

# Install the go-tdx-guest 'check' tool at a known good version
RUN go install github.com/google/go-tdx-guest/tools/check@v0.3.1

FROM ubuntu:22.04

ARG DEBIAN_FRONTEND=noninteractive

# 1. Configure APT and install OS & build deps
RUN echo "Acquire::http::Pipeline-Depth 0;" > /etc/apt/apt.conf.d/99custom \
 && echo "Acquire::http::No-Cache true;" >> /etc/apt/apt.conf.d/99custom \
 && echo "Acquire::BrokenProxy    true;" >> /etc/apt/apt.conf.d/99custom \
 && apt-get update \
 && apt-get install -y --no-install-recommends \
    python3.11 python3.11-dev python3-pip python3.11-venv \
    build-essential libsqlcipher-dev sqlite3 \
    apt-transport-https ca-certificates curl gnupg lsb-release \
    gcc dirmngr \
    linux-modules-extra-gcp \
 && rm -rf /var/lib/apt/lists/* \
 && apt-get clean

COPY --from=tdx_builder /go/bin/check /usr/local/bin/check

# (Optional) verify it landed correctly
RUN /usr/local/bin/check --help

# 2. Create Python venv
RUN python3.11 -m venv /opt/venv

# 3. Install Python deps
WORKDIR /app
COPY requirements.txt /app/requirements.txt
RUN /opt/venv/bin/pip install --upgrade pip \
 && /opt/venv/bin/pip install --no-cache-dir -r /app/requirements.txt

# 4. Install Intel TDX CLI
RUN curl -fsSL https://github.com/intel/trustauthority-client-for-go/raw/refs/heads/main/release/install-tdx-cli.sh | bash

# 5. Install Google Cloud SDK
RUN echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" \
      > /etc/apt/sources.list.d/google-cloud-sdk.list \
 && curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg \
      | gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg \
 && apt-get update \
 && apt-get install -y --no-install-recommends google-cloud-sdk \
 && rm -rf /var/lib/apt/lists/*

# 6. Copy application code & placeholder cert dir
COPY fithealth_service.py /app/fithealth_service.py
RUN mkdir /certs

# 7. Use venv’s Python by default
ENV PATH="/opt/venv/bin:${PATH}"

# 8. Expose HTTPS port
EXPOSE 443

# 9. Run the Flask service (with SSL inside)
ENTRYPOINT ["python", "fithealth_service.py"]
