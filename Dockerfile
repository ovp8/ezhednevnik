FROM python:3.12-slim

ENV PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    HOST=0.0.0.0 \
    DISTRIBUTION_MODE=False

RUN apt-get update \
    && apt-get install -y --no-install-recommends unzip \
    && rm -rf /var/lib/apt/lists/*

# 1) Раскладываем приложение в /srv/app независимо от структуры загрузки:
#    подойдёт daily-planner-hf.zip, любой другой zip или файлы прямо в репозитории
COPY . /tmp/ctx
RUN set -e; \
    echo "=== 1. Файлы репозитория:"; ls -la /tmp/ctx; \
    rm -rf /srv/app /tmp/unz; mkdir -p /srv/app /tmp/unz; \
    Z=""; for f in /tmp/ctx/*.zip /tmp/ctx/*.ZIP; do if [ -f "$f" ]; then Z="$f"; break; fi; done || true; \
    if [ -n "$Z" ]; then \
        echo "=== 2. Распаковка $Z"; unzip -q "$Z" -d /tmp/unz; \
    else \
        echo "=== 2. ZIP не найден — беру файлы прямо из репозитория"; cp -a /tmp/ctx/. /tmp/unz/; \
    fi; \
    P=$(find /tmp/unz -name requirements-ios.txt | head -n 1); \
    if [ -z "$P" ]; then P=$(find /tmp/unz -name iphone_server.py | head -n 1); fi; \
    SRC=$(dirname "$P"); \
    echo "=== 3. Каталог приложения: $SRC"; \
    if [ ! -f "$SRC/iphone_server.py" ]; then \
        echo "!!! iphone_server.py не найден — в репозитории нет архива с приложением"; \
        find /tmp/unz -maxdepth 3 | head -40; exit 1; \
    fi; \
    cp -a "$SRC"/. /srv/app/; \
    rm -rf /tmp/ctx /tmp/unz; \
    echo "=== 4. Итог в /srv/app:"; ls /srv/app

# 2) Зависимости сервера — фиксированные версии прямо здесь,
#    независимо от того, какие requirements внутри архива
RUN pip install --no-cache-dir \
    flet==0.86.5 \
    flet-web==0.86.5 \
    uvicorn==0.44.0 \
    websockets==16.0 \
    fastapi==0.128.0 \
    pywebpush==2.5.0 \
    py-vapid==1.9.6 \
    http_ece \
    cryptography \
    requests \
    certifi \
    tzdata

RUN useradd -m -u 1000 user \
    && chown -R user:user /srv

USER user
WORKDIR /srv/app

CMD ["python", "iphone_server.py"]

