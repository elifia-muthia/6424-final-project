FROM python:3.11-slim

# 1. Configure APT and install OS & build deps
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      build-essential \
      libsqlcipher-dev \
      libsqlite3-dev \
      python3.11-venv \
      apt-transport-https \
      ca-certificates \
      curl \
      gnupg \
 && rm -rf /var/lib/apt/lists/*

# 2. Create Python venv
RUN python3 -m venv /opt/venv

# 3. Install Python deps
WORKDIR /app
COPY requirements.txt /app/requirements.txt
RUN /opt/venv/bin/pip install --upgrade pip \
 && /opt/venv/bin/pip install --no-cache-dir -r /app/requirements.txt

# 4. Install Google Cloud SDK
RUN echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" \
      > /etc/apt/sources.list.d/google-cloud-sdk.list \
 && curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg \
      | gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg \
 && apt-get update \
 && apt-get install -y --no-install-recommends google-cloud-sdk \
 && rm -rf /var/lib/apt/lists/*

# 5. Copy application code & placeholder cert dir
COPY . /app
RUN mkdir /certs

# 6. Use venv’s Python by default
ENV PATH="/opt/venv/bin:${PATH}"

# 7. Expose HTTPS port
EXPOSE 443

# 8. Run the Flask service (with SSL inside)
CMD ["python", "fithealth_service.py"]
