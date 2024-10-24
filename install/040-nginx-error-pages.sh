#!/bin/bash

# Check if script is run as root
if [ "$EUID" -ne 0 ]; then 
    echo "Please run as root or with sudo"
    exit 1
fi

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Define source and destination directories using absolute path
SRC_DIR="$SCRIPT_DIR/error-pages"
DEST_DIR="/var/www/error-pages"

# Check if source directory exists
if [ ! -d "$SRC_DIR" ]; then
    echo "Source directory '$SRC_DIR' not found"
    exit 1
fi

# Create destination directory if it doesn't exist
mkdir -p "$DEST_DIR"

# Copy all .html files
echo "Copying error page files..."
cp -v "$SRC_DIR"/*.html "$DEST_DIR/"

# Set proper permissions
echo "Setting permissions..."

# Set directory ownership and permissions
sudo chown root:root /var/www/error-pages
sudo chmod 755 /var/www/error-pages

# Set file ownership and permissions
sudo chown root:root /var/www/error-pages/*
sudo chmod 644 /var/www/error-pages/*
