#!/bin/bash

# Flutter Setup Script for GitHub Codespaces
echo "🚀 Setting up Flutter development environment..."

# Update package list
sudo apt-get update

# Install required dependencies
sudo apt-get install -y \
    curl \
    git \
    unzip \
    xz-utils \
    zip \
    libglu1-mesa \
    openjdk-11-jdk

# Download and install Flutter
echo "📥 Downloading Flutter..."
cd /workspaces/AluminumFormworkCRM
curl -O https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.32.8-stable.tar.xz
tar xf flutter_linux_3.32.8-stable.tar.xz

# Add Flutter to PATH
export PATH="$PATH:`pwd`/flutter/bin"
echo 'export PATH="$PATH:'`pwd`'/flutter/bin"' >> ~/.bashrc

# Accept Android licenses
echo "📱 Setting up Android toolchain..."
flutter doctor --android-licenses

# Run Flutter doctor
echo "🔍 Running Flutter doctor..."
flutter doctor

# Get project dependencies
echo "📦 Installing project dependencies..."
flutter pub get

echo "✅ Flutter setup complete!"
echo "🎯 You can now run: flutter run -d web-server" 