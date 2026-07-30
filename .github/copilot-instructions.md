# EIC Software Environment - GitHub Copilot Instructions

This repository provides a comprehensive development environment for the Electron-Ion Collider (EIC) software ecosystem using containerized tools. When working with code in this environment or derived repositories, consider the following context and best practices.

## Environment Overview

This development environment is based on the `eic_xl:nightly` container image which includes:

### Core Physics Software Stack
- **Geant4**: Monte Carlo simulation toolkit for high energy physics
- **ROOT**: Data analysis framework with C++ and Python bindings
- **DD4hep**: Detector description toolkit for high energy physics experiments
- **Acts**: A Common Tracking Software for track reconstruction
- **Podio**: Plain Old Data I/O for event data models

### EIC-Specific Software
- **Epic**: EIC detector geometry and simulation framework
- **EICrecon**: EIC reconstruction software framework
- **Gaudi**: Event processing framework
- **GenFit**: Generic track fitting toolkit

### Development Tools
- **GCC**: C++ compiler with C++17 standard support
- **CMake**: Build system generator
- **Python**: With scientific computing packages (numpy, pip)
- **pkg-config**: Library configuration management
- **Emacs**: Text editor with physics-specific configurations

### Visualization and Analysis
- **Qt**: GUI framework (for Geant4 visualization)
- **OpenGL**: Graphics library support
- **Dawn/DawnCut**: Visualization tools for detector geometry
- **ImageMagick**: Image processing utilities

## Development Environment Setup

### For Template Repository Users
This repository serves as a template. When creating derived repositories:

1. **Use as Template**: Click "Use this template" on GitHub to create a new repository
2. **Codespaces Ready**: The devcontainer configuration is already set up for immediate use
3. **One-Click Development**: Use the "Open in GitHub Codespaces" badge for instant development environment

### For Derived Repository Development
When working in a repository that uses this template:

```bash
# The environment is pre-configured, so you can immediately use:
# - All EIC software tools
# - Physics simulation and reconstruction frameworks
# - Development and build tools
```

## Code Development Best Practices

### Physics Simulation Code
- Use Geant4 for detector simulations
- DD4hep for detector geometry descriptions
- ROOT for data analysis and histogramming
- Consider memory management for large-scale simulations

### Reconstruction Code
- EICrecon framework for reconstruction algorithms
- Acts for tracking implementations
- Gaudi for event processing workflows
- Use Podio for event data model definitions

### EIC Data Analysis
- **XRootD Access**: EIC simulation datasets available at `dtn-eic.jlab.org`
- **Data Productions**: Located in `/volatile/eic/EPIC/RECO/YY.MM.patch` directories
- **Jupyter Notebooks**: Preferred method for interactive data analysis
- **Uproot**: Efficient ROOT file reading for Python analysis
- **Latest Data**: Use most recent calendar-versioned production releases

### Build Systems
- CMake is the preferred build system
- Install software to `$EIC_SHELL_PREFIX` for integration
- Use pkg-config for library discovery
- Follow C++20 standards

### Common Development Patterns

#### CMake Project Setup
```cmake
cmake_minimum_required(VERSION 3.16)
project(MyEICProject)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Find EIC packages
find_package(DD4hep REQUIRED)
find_package(Geant4 REQUIRED)
find_package(ROOT REQUIRED)

# Your project configuration
```

#### ROOT Analysis Scripts
```cpp
// ROOT scripts can use all available libraries
#include "TFile.h"
#include "TTree.h"
// Physics analysis with full ROOT functionality
```

#### Python Development
```python
# Python environment includes scientific packages
import numpy as np
import ROOT  # ROOT Python bindings available
import uproot  # For reading ROOT files efficiently
# Use for data analysis and visualization
```

#### EIC Data Analysis with XRootD
```python
# Access EIC simulation data from public XRootD server
import uproot
import numpy as np
import matplotlib.pyplot as plt

# List available data productions
# xrdfs dtn-eic.jlab.org ls /volatile/eic/EPIC/RECO/25.04.1

# Open files directly from XRootD server
file_url = "root://dtn-eic.jlab.org//volatile/eic/EPIC/RECO/25.04.1/epic_craterlake/DIS/18x275/minQ2=1000/pythia8NCDIS_18x275_minQ2=1000_beamEffects_xAngle=-0.025_hiDiv_1.edm4hep.root"
with uproot.open(file_url) as file:
    tree = file["events"]
    # Access reconstructed data for analysis
```

## Container Environment Details

### Environment Variables
- `EIC_SHELL_PREFIX`: Installation prefix for user software
- Standard physics software environment variables are pre-configured

### File System Access
- Container includes bind mounts for common development directories
- Use `/tmp` for temporary files
- Install custom software to `$EIC_SHELL_PREFIX`

### Networking and Services
- Container supports X11 forwarding for GUI applications
- OpenGL support for 3D visualization
- Network access for downloading dependencies

## Integration with GitHub Codespaces

### Automatic Setup
- Devcontainer automatically loads the EIC environment
- No additional setup required for physics software
- Copilot context includes physics and EIC-specific knowledge

### Development Workflow
1. Open repository in Codespaces
2. Environment is immediately ready for EIC development
3. Use integrated terminal for command-line tools
4. VS Code extensions work with the containerized environment

### Performance Considerations
- Container includes optimized physics libraries
- Use appropriate Codespaces machine types for simulation work
- Consider memory requirements for large-scale analyses

## Extending This Environment

### Adding New Software
```bash
# Install to the EIC prefix for integration
cmake -DCMAKE_INSTALL_PREFIX=$EIC_SHELL_PREFIX ..
make install
```

### Custom Configurations
- Add configuration files to your derived repository
- Use environment variables for customization
- Consider container persistence for user preferences

## Troubleshooting

### Common Issues
- **Display Issues**: Ensure X11 forwarding is enabled for GUI applications
- **Memory Limits**: Large simulations may need Codespaces resource adjustments
- **Library Conflicts**: Use the pre-installed versions when possible

### Getting Help
- Check `eic-info` command inside container for software versions
- EIC software documentation: https://eic.github.io/
- Container issues: https://github.com/eic/eic-shell

## Best Practices for Copilot Usage

When using GitHub Copilot in this environment:
- Mention specific physics frameworks (Geant4, ROOT, DD4hep) in comments
- Include context about EIC detector systems when relevant
- Reference standard physics units and conventions
- Use framework-specific patterns and idioms

Example comment for better Copilot suggestions:
```cpp
// Create a Geant4 detector construction for EIC barrel electromagnetic calorimeter
// using DD4hep geometry and ROOT materials database
```

This environment provides everything needed for EIC software development, from detector simulation to data analysis, with full GitHub Codespaces and Copilot integration.

### EIC Data Analysis with Jupyter

The environment includes comprehensive support for analyzing EIC simulation data:

- **Sample Notebook**: `examples/eic_data_analysis.ipynb` provides a complete example of analyzing EIC datasets
- **XRootD Access**: Direct access to EIC data at `dtn-eic.jlab.org` without local downloads
- **Analysis Tools**: Pre-configured with uproot, matplotlib, pandas, and scientific Python stack
- **Jupyter Lab**: Start with `jupyter lab --ip=0.0.0.0 --port=8888 --no-browser --allow-root`

#### Quick Start for Data Analysis:
```bash
# Start Jupyter Lab (automatically configured in Codespaces)
jupyter lab --ip=0.0.0.0 --port=8888 --no-browser --allow-root

# Or run the example notebook directly
jupyter nbconvert --execute examples/eic_data_analysis.ipynb --to html
```

The sample notebook demonstrates:
- Accessing EIC simulation data from XRootD servers
- Reading EDM4hep files with uproot
- Basic track and particle analysis
- Physics plots (pT, η, φ distributions)
- Invariant mass calculations
- Standard EIC analysis patterns