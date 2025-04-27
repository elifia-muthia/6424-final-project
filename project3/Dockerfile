# Use Debian slim as a base
FROM python:3.11-slim

# ─── ARGUMENTS ───────────────────────────────────────────────────────────────
ARG DEBIAN_FRONTEND=noninteractive
# ────────────────────────────────────────────────────────────────────────────

# ─── 1. Install OS dependencies ───────────────────────────────────────────────
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      build-essential \
      curl \
      gnupg \
      lsb-release \
      ca-certificates \
      sqlite3 \
      libsqlite3-dev \
      vim-tiny && \
    rm -rf /var/lib/apt/lists/*

# ─── 2. Install SQLCipher and Python binding ─────────────────────────────────
RUN apt-get update && \
    apt-get install -y --no-install-recommends libsqlcipher-dev && \
    pip install --no-cache-dir pysqlcipher3 && \
    rm -rf /var/lib/apt/lists/*

# ─── 3. Install Intel TDX Attestation CLI ────────────────────────────────────
RUN curl -fsSL https://downloads.intel.com/tdx-attestation/cli/install.sh | bash

# ─── 4. Install Google Cloud SDK ─────────────────────────────────────────────
RUN echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" \
      > /etc/apt/sources.list.d/google-cloud-sdk.list && \
    curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg \
      | gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg && \
    apt-get update && \
    apt-get install -y --no-install-recommends google-cloud-sdk && \
    rm -rf /var/lib/apt/lists/*

# ─── 5. Install Python dependencies ───────────────────────────────────────────
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# ─── 6. Copy application code ─────────────────────────────────────────────────
COPY fithealth_service.py .

# ─── 7. Expose HTTPS port ─────────────────────────────────────────────────────
EXPOSE 443

# ─── 8. Entrypoint ────────────────────────────────────────────────────────────
# Use exec form so signals are forwarded correctly.
ENTRYPOINT ["python", "fithealth_service.py"]
