# 第一阶段：安装依赖项
FROM python:3.11-slim-bookworm AS builder

WORKDIR /app/zhenxun

# 复制项目文件
COPY . /app/zhenxun

# 更新包列表并安装必要的依赖项
RUN apt update && \
    apt upgrade -y && \
    apt install -y --no-install-recommends \
    gcc \
    g++ && \
    apt clean

# 安装 Poetry 并设置不使用虚拟环境
RUN pip install poetry
ENV POETRY_VIRTUALENVS_CREATE=false

# 安装项目依赖项
RUN poetry install

# 安装 Playwright 及其依赖项
RUN poetry run playwright install --with-deps chromium

# 清理不必要的依赖项
RUN apt purge -y gcc g++ && \
    apt autoremove -y && \
    apt clean && \
    rm -rf /var/lib/apt/lists/*

# 第二阶段：运行应用
FROM python:3.11-slim-bookworm

EXPOSE 8080

WORKDIR /app/zhenxun

# 安装运行时所需的系统依赖
RUN apt update && \
    apt install -y --no-install-recommends \
    libgl1-mesa-glx \
    libglib2.0-0 \
    libnss3 \
    libnspr4 \
    libatk1.0-0 \
    libatk-bridge2.0-0 \
    libcups2 \
    libdrm2 \
    libxkbcommon0 \
    libxcomposite1 \
    libxdamage1 \
    libxfixes3 \
    libxrandr2 \
    libgbm1 \
    libasound2 \
    libpango-1.0-0 \
    libcairo2 \
    && apt clean && \
    rm -rf /var/lib/apt/lists/*

# 复制依赖项和应用代码
COPY --from=builder /usr/local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages
COPY --from=builder /app/zhenxun /app/zhenxun
# 复制 Playwright 浏览器
COPY --from=builder /root/.cache/ms-playwright /root/.cache/ms-playwright

# 设置数据和资源目录
VOLUME /app/zhenxun/data /app/zhenxun/resources /app/zhenxun/.env.dev

# 设置默认命令
CMD ["python", "bot.py"]
