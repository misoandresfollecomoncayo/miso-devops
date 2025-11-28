# Build Base
# IMPORTANTE: Forzar arquitectura AMD64 para ECS Fargate
FROM --platform=linux/amd64 public.ecr.aws/docker/library/python:3.12-slim AS base
#FROM python:3.12-slim AS base

ENV PYTHONPATH=/app/src

WORKDIR /app

COPY requirements.txt .

# Dependencias de sistema necesarias para psycopg2-binary (y compilación si hiciera falta)
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential libpq-dev curl ca-certificates \
    && rm -rf /var/lib/apt/lists/*

#Runtime
FROM base AS runtime

RUN pip install --upgrade pip \
    && pip install -r requirements.txt

##Se copia el codigo de la app
COPY src /app/src
COPY newrelic.ini /app/newrelic.ini

##Variables por defecto
ENV DB_USER=postgres
ENV DB_PASSWORD=postgres
ENV DB_NAME=dbdevops
ENV DB_HOST=db-postgres-devops.c6n2e2wes55q.us-east-1.rds.amazonaws.com
ENV DB_PORT=5432

EXPOSE 5000

#Arranque con New Relic
CMD ["newrelic-admin", "run-program", "python", "-m", "src.app"]