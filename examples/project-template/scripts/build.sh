#!/bin/bash
# Build script for EIC project template

echo "Building EIC project template..."

# Create build directory
mkdir -p build
cd build

# Configure with CMake
echo "Configuring with CMake..."
cmake ..

# Build the project
echo "Building..."
make -j$(nproc)

echo "Build complete! Run with: ./eic_example"