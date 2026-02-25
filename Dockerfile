# syntax=docker/dockerfile:1
# Builds OpenClaw Mission Control backend from upstream source.
# Upstream: https://github.com/abhi1693/openclaw-mission-control

# Stage 1: Clone upstream source
FROM alpine/git AS source
RUN git clone --depth=1 https://github.com/abhi1693/openclaw-mission-control.git /upstream

# Stage 2: Base
FROM python:3.12-slim AS base
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1
WORKDIR /app
RUN apt-get update \
  && apt-get install -y --no-install-recommends curl ca-certificates \
  && rm -rf /var/lib/apt/lists/*
RUN curl -LsSf https://astral.sh/uv/install.sh | sh
ENV PATH="/root/.local/bin:${PATH}"

# Stage 3: Install dependencies
FROM base AS deps
COPY --from=source /upstream/backend/pyproject.toml /upstream/backend/uv.lock ./
RUN uv sync --frozen --no-dev

# Stage 4: Runtime
FROM base AS runtime
COPY --from=deps /app/.venv /app/.venv
ENV PATH="/app/.venv/bin:${PATH}"
COPY --from=source /upstream/backend/migrations ./migrations
COPY --from=source /upstream/backend/alembic.ini ./alembic.ini
COPY --from=source /upstream/backend/app ./app
COPY --from=source /upstream/backend/templates ./templates
EXPOSE 8000
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
