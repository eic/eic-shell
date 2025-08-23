cmake_minimum_required(VERSION 3.16)
project(EICProjectTemplate)

# Set C++ standard
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Find required EIC packages
find_package(DD4hep REQUIRED)
find_package(Geant4 REQUIRED)
find_package(ROOT REQUIRED)

# Include directories
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/include)

# Add executable
add_executable(eic_example src/main.cpp)

# Link libraries
target_link_libraries(eic_example 
    ${DD4hep_LIBRARIES}
    ${Geant4_LIBRARIES}
    ${ROOT_LIBRARIES}
)

# Installation
install(TARGETS eic_example DESTINATION bin)