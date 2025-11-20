#!/bin/bash
# Script to create notification icons for Android
# This creates properly sized notification icons for different screen densities

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}Creating notification icons...${NC}"

# Base directory
RES_DIR="app/src/main/res"
LAUNCHER_ICON="$RES_DIR/mipmap-xxxhdpi/launcher_icon.png"

# Check if launcher icon exists
if [ ! -f "$LAUNCHER_ICON" ]; then
    echo "Error: Launcher icon not found at $LAUNCHER_ICON"
    exit 1
fi

echo "Using launcher icon: $LAUNCHER_ICON"

# Create notification icons for each density
# Format: "density:size"
DENSITIES="mdpi:24 hdpi:36 xhdpi:48 xxhdpi:72 xxxhdpi:96"

for item in $DENSITIES; do
    density=$(echo $item | cut -d: -f1)
    size=$(echo $item | cut -d: -f2)

    output_dir="$RES_DIR/drawable-$density"
    output_file="$output_dir/ic_notification.png"

    # Create output directory
    mkdir -p "$output_dir"

    # Create a resized version of the launcher icon
    sips -z $size $size "$LAUNCHER_ICON" --out "/tmp/ic_temp_$density.png" > /dev/null 2>&1

    # Copy to final location
    cp "/tmp/ic_temp_$density.png" "$output_file"

    # Clean up temp file
    rm "/tmp/ic_temp_$density.png"

    echo -e "${GREEN}✓${NC} Created $output_file (${size}x${size}px)"
done

echo -e "\n${GREEN}✅ Notification icons created successfully!${NC}"
echo ""
echo "Note: These icons are resized versions of your launcher icon."
echo "For production, create proper monochrome white notification icons using:"
echo "  Android Studio → Right-click res → New → Image Asset → Notification Icons"
