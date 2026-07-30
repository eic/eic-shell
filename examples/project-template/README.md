# EIC Project Template

This directory contains a template project structure that demonstrates how to organize and build EIC software projects using the development environment.

## Structure

```
project-template/
├── CMakeLists.txt          # CMake build configuration
├── src/                    # Source code
│   └── main.cpp           # Example application
├── include/               # Header files (empty in template)
├── scripts/               # Build and utility scripts
│   └── build.sh          # Build automation script
└── analysis/             # Analysis scripts and notebooks
```

## Building

The environment includes all necessary tools pre-installed:

```bash
# Use the provided build script
./scripts/build.sh

# Or manually:
mkdir build && cd build
cmake ..
make -j$(nproc)
```

## Usage in Derived Repositories

When creating a new EIC software project:

1. Copy this structure to your repository
2. Modify `CMakeLists.txt` for your specific dependencies
3. Replace example code with your implementation
4. Use GitHub Codespaces with the EIC environment for development

The development environment provides:
- All EIC software frameworks (DD4hep, Geant4, ROOT, etc.)
- Configured build tools and compilers
- GitHub Copilot with physics software context
- VS Code extensions for C++, CMake, and Python development