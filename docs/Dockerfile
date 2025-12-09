FROM python:3.11-slim

WORKDIR /docs

# Install make and basic build tools
RUN apt-get update && apt-get install -y make && rm -rf /var/lib/apt/lists/*

# Install requirements
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt && \
    pip install --no-cache-dir sphinx-autobuild

# Default command can be overridden in docker-compose
CMD ["/bin/bash"]
