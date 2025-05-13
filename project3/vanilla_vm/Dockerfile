FROM python:3.11-slim

WORKDIR /app
COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

# Expose port 80
EXPOSE 80

CMD ["python", "fithealth_service.py"]
