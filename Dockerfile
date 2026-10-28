FROM python:3.12-slim

ENV PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    HOST=0.0.0.0 \
    DISTRIBUTION_MODE=False

RUN apt-get update \
    && apt-get install -y --no-install-recommends unzip \
    && rm -rf /var/lib/apt/lists/*

COPY . /tmp/ctx
RUN set -e; Z=$(ls /tmp/ctx/*.zip | head -n 1) \
    && unzip -q "$Z" -d /srv \
    && rm -rf /tmp/ctx \
    && pip install --no-cache-dir -r /srv/app/requirements-ios.txt

RUN useradd -m -u 1000 user \
    && chown -R user:user /srv

USER user
WORKDIR /srv/app

CMD ["python", "iphone_server.py"]
