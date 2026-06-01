# ── Stage 1: Build & Test ──────────────────────────────────────────────────
FROM python:3.11-slim AS builder

WORKDIR /build

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app/ ./app/
COPY tests/ ./tests/

# Run tests during build so a failing test breaks the image
RUN python -m pytest tests/ -v --tb=short

# ── Stage 2: Production image ───────────────────────────────────────────────
FROM python:3.11-slim AS production

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir flask==3.0.3

COPY app/ .

EXPOSE 5000

HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:5000/health')"

CMD ["python", "app.py"]
