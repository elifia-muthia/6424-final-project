FROM python:3.11-slim

# 1) Install build tools + SQLCipher dev libs + gcloud SDK
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      build-essential \
      libsqlite3-dev \
      libsqlcipher-dev \
      apt-transport-https \
      ca-certificates \
      gnupg \
 && mkdir -p /usr/share/keyrings \
 && curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg \
      | gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg \
 && echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] \
      https://packages.cloud.google.com/apt cloud-sdk main" \
      > /etc/apt/sources.list.d/google-cloud-sdk.list \
 && apt-get update \
 && apt-get install -y --no-install-recommends \
      google-cloud-sdk \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY requirements.txt ./

# 2) Now pip can build & install pysqlcipher3
RUN pip install --no-cache-dir -r requirements.txt

COPY . .
EXPOSE 80
CMD ["python", "fithealth_service.py"]
