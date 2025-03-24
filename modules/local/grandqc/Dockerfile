# Start with Python image
FROM ubuntu:22.04 AS builder
LABEL authors="Sameesh Kher" \
    description="Docker image for GrandQC"

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PATH="/venv/bin:$PATH"

# Set working directory inside the container
WORKDIR /app

# Install system dependencies for Python packages
# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    python3-venv \
    python3-pip \
    git \
    && rm -rf /var/lib/apt/lists/*

# Clone the repository (replace with your repo URL)
RUN git config --global http.sslverify false && \
    git clone https://github.com/cpath-ukk/grandqc.git && \
    cd grandqc && \
    git checkout 045b7a2d765ef0daa046609f93218312287a92d0

ADD data/ grandqc/01_WSI_inference_OPENSLIDE_QC/
ADD data/ grandqc/02_WSI_inference_OME_TIFF_QC/

# Activate virtual environment and install dependencies
RUN python3 -m venv /venv && \
    /venv/bin/pip install --no-cache-dir --upgrade pip && \
    /venv/bin/pip install --no-cache-dir openslide-python==1.4.1 openslide-bin==4.0.0.6 && \
    /venv/bin/pip install --no-cache-dir -r grandqc/requirements.txt


# Second stage: Use a clean Ubuntu runtime
FROM ubuntu:22.04

# Install only Python in the final runtime environment
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    && rm -rf /var/lib/apt/lists/*


# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PATH="/venv/bin:$PATH" \
    OPENSLIDE_QC="/app/grandqc/01_WSI_inference_OPENSLIDE_QC" \
    OME_TIFF_QC="/app/grandqc/02_WSI_inference_OME_TIFF_QC" \
    TISSUE_MODELS="/app/grandqc/02_WSI_inference_OME_TIFF_QC/models" \
    ARTIFACT_MODELS="/app/grandqc/01_WSI_inference_OPENSLIDE_QC/models/"

# Create a non-root user for security
RUN useradd --create-home gqcuser
USER gqcuser

# Set working directory inside the container
WORKDIR /app

# Copy virtual environment from builder stage
COPY --from=builder /venv /venv

# Copy only necessary application files from the cloned repository
COPY --from=builder app/grandqc/ grandqc/
