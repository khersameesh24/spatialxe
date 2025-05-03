# Dockerfile to create container with spatialdata

FROM python:3.10.12
LABEL authors="Florian Heyl" \
    description="Docker image containing spatialdata"

# Set environment variables
ENV PYTHONUNBUFFERED=1
# Set the environment variable NUMBA_CACHE_DIR
ENV NUMBA_CACHE_DIR '/tmp'

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Set the working directory
WORKDIR /app

# Copy the requirements directly into the image
RUN pip install --no-cache-dir spatialdata==0.2.6 dask==2024.8.0 dask-expr==1.1.10 dask-image==2023.3.0 spatialdata-io==0.1.4
