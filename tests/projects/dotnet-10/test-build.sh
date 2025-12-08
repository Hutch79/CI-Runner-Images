#!/bin/bash

# Build script for .NET 10 demo application
# This script builds the application located in ./data

set -e  # Exit on any error

echo "Building .NET 10 demo application..."

# Navigate to the data directory where the solution is located
cd ./data

# Restore NuGet packages
echo "Restoring NuGet packages..."
dotnet restore

# Build the solution in Release configuration
echo "Building the solution..."
dotnet build --configuration Release --no-restore

# Publish the application (optional, but useful for testing)
echo "Publishing the application..."
dotnet publish ./src/DotNet-10.Demo/DotNet-10.Demo.csproj --configuration Release --output ./publish --no-build

echo "Build completed successfully!"
echo "Published application is available in ./data/publish/"

# Run the published application to verify it works
echo "Running the application..."
./publish/DotNet-10.Demo

echo "Application ran successfully!"
