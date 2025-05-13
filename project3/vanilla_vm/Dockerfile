FROM python:3.11-slim

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      build-essential \
      libsqlcipher-dev \
      libsqlite3-dev \
      curl \
      gnupg \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY requirements.txt ./

RUN pip install --no-cache-dir -r requirements.txt

RUN echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" \
      > /etc/apt/sources.list.d/google-cloud-sdk.list \
 && curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg \
      | gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg \
 && apt-get update \
 && apt-get install -y --no-install-recommends google-cloud-sdk \
 && rm -rf /var/lib/apt/lists/*

COPY . .
EXPOSE 80
CMD ["python", "fithealth_service.py"]
