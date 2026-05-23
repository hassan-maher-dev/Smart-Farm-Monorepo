FROM python:3.9-slim
WORKDIR /app

# Install dependencies for PostgreSQL
RUN apt-get update && apt-get install -y libpq-dev gcc

# Enable unbuffered logging to see errors in K8s immediately
ENV PYTHONUNBUFFERED=1

COPY requirements.txt .

# أضفنا gunicorn هنا عشان نضمن إنه ينزل حتى لو مش مكتوب في requirements.txt
RUN pip install --no-cache-dir -r requirements.txt gunicorn

COPY . .

EXPOSE 5002

# تشغيل التطبيق بسيرفر إنتاج قوي وإجباره على بورت 5002
CMD ["gunicorn", "--bind", "0.0.0.0:5002", "--workers", "2", "--threads", "4", "--timeout", "120", "app:app"]