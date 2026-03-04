# build stage
FROM python:3.11-slim AS build
WORKDIR /app
COPY requirements.txt .
RUN pip install --upgrade pip && pip install --no-cache-dir -r requirements.txt

# final stage
# FROM python:3.11-slim
# WORKDIR /app
# COPY --from=build /usr/local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages
# COPY . .
# ENV PYTHONUNBUFFERED=1
# EXPOSE 8000
# CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]