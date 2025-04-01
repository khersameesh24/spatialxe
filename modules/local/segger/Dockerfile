# Base image with CUDA 12.1 runtime and cuDNN
FROM nvidia/cuda:12.1.1-cudnn8-runtime-ubuntu22.04

# Install essential system tools and Python
RUN apt-get update -y && apt-get install -y --no-install-recommends \
    git \
    wget \
    curl \
    unzip \
    htop \
    vim \
    build-essential \
    python3 \
    python3-pip \
    python3-venv \
    && apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create a symbolic link to enable `python` instead of `python3`
RUN ln -s /usr/bin/python3 /usr/bin/python

# Install global python tools
RUN python -m pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir debugpy jupyterlab

# Set working directory
WORKDIR /workspace

# Clone the repository and install segger with CUDA 12 support
RUN git clone https://github.com/EliHei2/segger_dev.git /workspace/segger_dev && \
    pip install -e "/workspace/segger_dev[cuda12]"

# Set environment variables
ENV PYTHONPATH=/workspace/segger_dev/src:$PYTHONPATH
ENV SEGGER_CREATE_DATASET="/workspace/segger_dev/src/segger/cli/create_dataset_fast.py"
ENV SEGGER_TRAIN_MODEL="/workspace/segger_dev/src/segger/cli/train_model.py"
ENV SEGGER_PREDICT="/workspace/segger_dev/src/segger/cli/predict_fast.py"
ENV CUPY_CACHE_DIR="/tmp/cupy_cache"

# Create a non-root user for security
RUN useradd --create-home seguser
USER seguser

ENTRYPOINT [ "/bin/bash" ]
