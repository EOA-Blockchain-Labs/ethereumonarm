# Contributing to Ethereum on ARM

Thank you for your interest in contributing to Ethereum on ARM! This document provides guidelines and instructions for contributing to the project.

## 🚀 Getting Started

### Development Environment

1. **Fork the repository** and clone your fork:

   ```bash
   git clone https://github.com/YOUR_USERNAME/ethereumonarm.git
   cd ethereumonarm
   ```

2. **Set up the build environment** (for package building):

   ```bash
   cd fpm-package-builder
   vagrant up
   vagrant ssh
   ```

3. **Set up documentation** (for docs contributions):

   ```bash
   cd docs
   pip install -r requirements.txt
   make html
   ```

## 📝 Code Style

- **Shell scripts**: Follow [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html)
- **Use shellcheck** to lint your scripts before submitting
- **Indentation**: 4 spaces for shell scripts, tabs for Makefiles
- All files should end with a newline

We use `.editorconfig` to maintain consistent formatting—please ensure your editor supports it.

## 🔄 Pull Request Process

1. **Create a feature branch** from `main`:

   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes** and commit with clear messages:

   ```bash
   git commit -m "feat(component): add new feature"
   ```

   We follow [Conventional Commits](https://www.conventionalcommits.org/) format:
   - `feat:` new features
   - `fix:` bug fixes
   - `docs:` documentation changes
   - `chore:` maintenance tasks

3. **Test your changes** locally before submitting

4. **Submit a Pull Request** with:
   - Clear description of changes
   - Link to any related issues
   - Screenshots for UI changes (if applicable)

## 🐛 Reporting Issues

When reporting bugs, please include:

- Device model and specifications
- Ubuntu/Armbian version
- Client packages and versions
- Steps to reproduce the issue
- Relevant logs (from `journalctl`)

## 📦 Package Contributions

To add a new package, use our **Templates** to get started quickly.

We have a comprehensive guide available at:
`fpm-package-builder/build-scripts/templates/HOWTO_ADD_PROJECT.md`

**Quick Start:**

1. **Copy the template**:

    ```bash
    cp -r fpm-package-builder/build-scripts/templates/ fpm-package-builder/<category>/<new-project>
    ```

2. **Follow the guide**: Read the `HOWTO_ADD_PROJECT.md` inside the templates (or the source one) to rename and configure your files.
3. **Test**: Build using the Vagrant environment.

## 📚 Documentation

Documentation uses Sphinx with reStructuredText format. To preview changes:

```bash
cd docs
make html
# Open _build/html/index.html in a browser
```

## ❓ Questions?

- Join our [Discord](https://discord.gg/ve2Z8fxz5N)
- Follow us on [Twitter/X](https://x.com/EthereumOnARM)

Thank you for contributing to decentralization! 🙏
