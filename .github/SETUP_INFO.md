# EIC-Shell Copilot Integration Setup

This repository has been configured to provide comprehensive GitHub Copilot support for EIC (Electron-Ion Collider) software development. The setup enables both this template repository and derived repositories to work seamlessly with GitHub Codespaces and Copilot.

## What's Included

### 1. Copilot Instructions (`.github/copilot-instructions.md`)
Provides GitHub Copilot with detailed context about:
- EIC software environment and available tools
- Physics frameworks (Geant4, ROOT, DD4hep, Acts)
- EIC-specific software (Epic, EICrecon, Podio, Gaudi)
- Development best practices and common patterns
- Container environment details and usage

### 2. Enhanced DevContainer Configuration (`.devcontainer/devcontainer.json`)
- Uses the `eic_xl:nightly` container with complete EIC software stack
- Pre-configured VS Code extensions for C++, CMake, and Python
- Proper environment variables and development settings
- Port forwarding for web-based tools and services
- GUI support with security configurations

### 3. Template Repository Configuration (`.github/template.yml`)
- Configures this repository as a GitHub template
- Appropriate tags for physics and simulation development
- Clear description for discoverability

### 4. Usage Documentation
- **Template Usage Guide** (`.github/TEMPLATE_USAGE.md`): Detailed instructions for using this as a template
- **Example Project** (`examples/project-template/`): Complete project structure with CMake setup
- **Updated README**: Clear template usage instructions

## For Repository Maintainers

The copilot instructions are designed to:
- Give Copilot comprehensive context about EIC physics software
- Provide framework-specific guidance for better code suggestions
- Include troubleshooting and best practices information
- Support both simulation and analysis workflows

## For Derived Repository Users

When you create a repository from this template:
1. All copilot instructions carry over automatically
2. Devcontainer provides instant development environment
3. GitHub Copilot understands the physics context
4. Example project structure shows organization patterns

The environment includes everything needed for EIC software development with no additional setup required.

## Testing and Validation

- DevContainer JSON syntax validated
- Template YAML configuration verified  
- Example project structure tested
- Documentation cross-references confirmed

This setup provides a complete development environment for EIC physics software with intelligent coding assistance through GitHub Copilot.