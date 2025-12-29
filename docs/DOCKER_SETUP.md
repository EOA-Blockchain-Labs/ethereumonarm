# 🐳 Docker Setup for Documentation

[![Docker](https://img.shields.io/badge/Docker-Required-2496ED?logo=docker&logoColor=white)](https://www.docker.com/)
[![Sphinx](https://img.shields.io/badge/Sphinx-Documentation-000000?logo=sphinx&logoColor=white)](https://www.sphinx-doc.org/)

This directory contains a Docker-based development environment for building and previewing the Ethereum on ARM documentation locally.

---

## 📋 Prerequisites

- **Docker** and **Docker Compose** installed on your system
- Basic familiarity with terminal/command line

> **💡 Tip**: If you don't have Docker installed, visit [docs.docker.com/get-docker](https://docs.docker.com/get-docker/)

---

## 🚀 Quick Start

### 1. Build the Docker Image

```bash
docker compose build
```

This creates a container with all necessary dependencies (Sphinx, themes, extensions).

### 2. Start the Documentation Server

```bash
docker compose up
```

The documentation will be built and served at:

**🌐 <http://localhost:8000>**

> **📝 Note**: The server watches for file changes and automatically rebuilds the documentation.

### 3. Stop the Server

Press `Ctrl+C` in the terminal, or run:

```bash
docker compose down
```

---

## 🛠️ Advanced Usage

### Rebuild Without Cache

If you've updated dependencies in `requirements.txt`:

```bash
docker compose build --no-cache
```

### View Build Logs

```bash
docker compose logs -f
```

### Run a One-Time Build

To build HTML without starting the server:

```bash
docker compose run --rm sphinx make html
```

Output will be in `_build/html/`.

---

## 📁 Project Structure

```
docs/
├── conf.py              # Sphinx configuration
├── requirements.txt     # Python dependencies
├── Dockerfile          # Container definition
├── docker-compose.yml  # Service orchestration
└── _build/             # Generated HTML (gitignored)
```

---

## 🐛 Troubleshooting

### Port Already in Use

If port 8000 is occupied, edit `docker-compose.yml`:

```yaml
ports:
  - "8001:8000"  # Change 8001 to any available port
```

### Permission Issues

On Linux, if you encounter permission errors:

```bash
sudo chown -R $USER:$USER _build/
```

### Container Won't Start

Remove existing containers and rebuild:

```bash
docker compose down
docker compose build --no-cache
docker compose up
```
