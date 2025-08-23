# Using EIC-Shell Template for Your Repository

This document explains how to use the eic-shell template repository to set up GitHub Codespaces with Copilot support for EIC software development.

## Quick Start

### For New Repositories

1. **Create from Template**:
   - Go to [eic/eic-shell](https://github.com/eic/eic-shell)
   - Click "Use this template" → "Create a new repository"
   - Choose your repository name and settings

2. **Start Codespaces**:
   - In your new repository, click the "Code" button
   - Select "Codespaces" tab → "Create codespace on main"
   - The EIC development environment will load automatically

3. **Begin Development**:
   - All EIC software tools are pre-installed and configured
   - GitHub Copilot has context about the EIC software stack
   - Start coding immediately with physics simulation and analysis tools

### For Existing Repositories

1. **Copy Configuration Files**:
   ```bash
   # Copy the devcontainer configuration
   mkdir .devcontainer
   cp path/to/eic-shell/.devcontainer/devcontainer.json .devcontainer/
   
   # Copy the copilot instructions
   mkdir .github
   cp path/to/eic-shell/.github/copilot-instructions.md .github/
   ```

2. **Customize for Your Project**:
   - Modify `.devcontainer/devcontainer.json` if needed
   - Add project-specific dependencies or configurations
   - Update copilot instructions with project context

## Available Software

Your Codespaces environment includes:

### Physics Frameworks
- **Geant4**: For detector simulation
- **ROOT**: For data analysis and visualization  
- **DD4hep**: For detector description
- **Acts**: For track reconstruction

### EIC Software
- **Epic**: EIC detector geometry framework
- **EICrecon**: EIC reconstruction software
- **Podio**: Event data models
- **Gaudi**: Event processing framework

### Development Tools  
- **GCC/G++**: C++17 compatible compiler
- **CMake**: Build system
- **Python**: With scientific packages
- **VS Code Extensions**: C++, CMake, Python support

## Development Workflow

### 1. Environment Setup
No setup required! The container includes everything pre-configured.

### 2. Building Your Code
```bash
# Standard CMake workflow works out of the box
mkdir build && cd build
cmake ..
make -j$(nproc)
```

### 3. Running Simulations
```bash
# Geant4 applications work with visualization
./your_geant4_app

# ROOT analysis with GUI support
root -l analysis.C
```

### 4. Using Copilot
GitHub Copilot understands the EIC physics context:
- Reference specific frameworks in comments
- Use physics terminology for better suggestions
- Mention detector components and analysis patterns

Example:
```cpp
// Create electromagnetic calorimeter geometry using DD4hep
// for EIC barrel region with lead-tungstate crystals
```

## Customization

### Adding Dependencies
Modify `.devcontainer/devcontainer.json`:
```json
{
  "name": "my-eic-project",
  "image": "ghcr.io/eic/eic_xl:nightly",
  "postCreateCommand": "pip install my-analysis-package"
}
```

### Project-Specific Tools
Add build scripts, analysis notebooks, or configuration files to your repository. The container will preserve them across sessions.

### Environment Variables
Set project-specific variables in the devcontainer:
```json
"containerEnv": {
  "MY_PROJECT_DATA": "/workspace/data",
  "DETECTOR_CONFIG": "epic_craterlake"
}
```

## Best Practices

### Code Organization
- Place simulation code in `src/simulation/`
- Keep analysis scripts in `analysis/`
- Store geometry files in `geometry/`
- Use `scripts/` for build and run helpers

### Documentation
- Document physics assumptions and detector configurations
- Include units in variable names and comments
- Reference EIC Technical Design Report sections when relevant

### Data Management
- Use appropriate data formats (ROOT, HDF5, etc.)
- Consider file sizes for Codespaces storage limits
- Use external storage for large datasets

## Troubleshooting

### Common Issues
- **GUI Applications**: Use VS Code's port forwarding for web-based visualizations
- **Large Builds**: Consider using Codespaces prebuilds for complex projects
- **Memory**: Use appropriate machine types for simulation workloads

### Getting Support
- EIC Software Documentation: https://eic.github.io/
- Template Issues: https://github.com/eic/eic-shell/issues
- EIC Software Forum: https://eic.phy.anl.gov/

## Examples

Check the [EIC Software Organization](https://github.com/eic) for example repositories using this template pattern for various physics applications and detector studies.