FROM python:3.10-slim

WORKDIR /app

# 复制源码（先复制，方便利用 Docker 构建缓存）
COPY . /app

# 合并所有安装、下载、清理步骤到单一层（关键！）
RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential libsndfile1 ffmpeg \
    && rm -rf /var/lib/apt/lists/* \
    \
    # 安装 CPU 版 PyTorch（核心改动，避免数 GB 的 CUDA 包）
    && pip install --upgrade pip \
    && pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu --no-cache-dir \
    \
    # 安装本项目（-e 开发模式），禁用缓存
    && pip install -e . --no-cache-dir \
    \
    # 下载所需语言资源
    && python -m unidic download \
    \
    # 下载模型（注意：此步约占用 1~1.5GB）
    && python melo/init_downloads.py \
    \
    # 彻底清理缓存（节省数百 MB）
    && rm -rf ~/.cache/pip ~/.cache/unidic /tmp/* \
    && apt-get clean

# 暴露端口（与 CMD 一致）
EXPOSE 8888

# 启动命令（保持与原版一致）
CMD ["python", "./melo/app.py", "--host", "0.0.0.0", "--port", "8888"]
