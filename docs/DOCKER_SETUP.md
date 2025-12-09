# Sphinx Docker Environment Setup

This directory contains a Dockerized environment to easily build and test the Sphinx documentation without installing dependencies on your local machine.

## Prerequisites

- [Docker](https://www.docker.com/get-started)
- [Docker Compose](https://docs.docker.com/compose/install/) (usually included with Docker Desktop/OrbStack)

## Getting Started

The setup uses `docker-compose` to manage the container and `sphinx-autobuild` to serve the documentation with live reloading.

### 1. Build the Docker Image

Build the image using the provided `Dockerfile` and `requirements.txt`:

```bash
docker compose build
```

### 2. Run the Documentation Server

Start the container in detached mode:

```bash
docker compose up -d
```

This command will:

- Mount your local `docs` directory to `/docs` inside the container.
- Start `sphinx-autobuild`.
- Expose the server on port **8000**.

### 3. Access the Documentation

Open your browser and navigate to:

[http://localhost:8000](http://localhost:8000)

### 4. Live Editing

The environment is configured for live reloading. When you edit any `.rst` file in your local directory, the documentation will automatically rebuild, and the browser page will refresh to show your changes.

## Troubleshooting

- **Port Conflicts**: If port 8000 is already in use, you can change the port mapping in `docker-compose.yml`:

  ```yaml
  ports:
    - "8080:8000"  # Changes host port to 8080
  ```

- **Rebuilding Dependencies**: If you modify `requirements.txt`, you need to rebuild the Docker image:

  ```bash
  docker compose build --no-cache
  docker compose up -d
  ```

## Stopping the Environment

To stop the container:

```bash
docker compose down
```
