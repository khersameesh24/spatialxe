# Dockerfile to create container for ficture

FROM python:3.10.12
LABEL authors="Florian Heyl" \
    description="Docker image for ficture"

# Set environment variables
ENV PYTHONUNBUFFERED=1
# Set the environment variable NUMBA_CACHE_DIR
ENV NUMBA_CACHE_DIR '/tmp'

# Set up matplotlib cache dir
ENV MPLCONFIGDIR=/tmp/.matplotlib
RUN mkdir -p $MPLCONFIGDIR

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    tabix \
    libgl1 \
    bc \
    && rm -rf /var/lib/apt/lists/*

# Set the working directory
WORKDIR /app

# Copy the requirements directly into the image
RUN pip install --no-cache-dir ficture==0.0.4.0 mpmath==1.3.0 PyQt5==5.15.11 PyQt5-sip==12.17.0
