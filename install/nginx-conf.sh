#!/bin/bash

# Check if script is run as root
if [ "$EUID" -ne 0 ]; then 
    echo "Please run as root or with sudo"
    exit 1
fi

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Define source and destination directories using absolute path
SRC_DIR="$SCRIPT_DIR/nginx-conf"
DEST_DIR="/etc/nginx/conf.d"

# Check if source directory exists
if [ ! -d "$SRC_DIR" ]; then
    echo "Source directory '$SRC_DIR' not found"
    exit 1
fi

# Create destination directory if it doesn't exist
mkdir -p "$DEST_DIR"

# Copy all .conf files
echo "Copying configuration files..."
cp -v "$SRC_DIR"/*.conf "$DEST_DIR/"

# Set proper permissions
echo "Setting permissions..."
chown root:root "$DEST_DIR"/*.conf
chmod 644 "$DEST_DIR"/*.conf
