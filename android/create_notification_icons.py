#!/usr/bin/env python3
"""
Script to create notification icons for Android from the launcher icon.
This creates white silhouette versions of the icon for different screen densities.

Usage: python3 create_notification_icons.py
"""

import os
import sys
from pathlib import Path

try:
    from PIL import Image, ImageOps, ImageDraw
except ImportError:
    print("ERROR: Pillow is not installed.")
    print("Install it with: pip3 install Pillow")
    sys.exit(1)

# Define icon sizes for different densities
DENSITIES = {
    'mdpi': 24,
    'hdpi': 36,
    'xhdpi': 48,
    'xxhdpi': 72,
    'xxxhdpi': 96,
}

def create_notification_icon_from_launcher(launcher_path, output_base_path):
    """Convert launcher icon to notification icon (white silhouette)."""
    try:
        # Open the launcher icon
        img = Image.open(launcher_path).convert('RGBA')

        # Get alpha channel for the shape
        alpha = img.split()[3]

        # Create white silhouette
        white_img = Image.new('RGBA', img.size, (255, 255, 255, 0))
        white_img.putalpha(alpha)

        return white_img
    except Exception as e:
        print(f"Error processing {launcher_path}: {e}")
        return None

def create_simple_bell_icon(size):
    """Create a simple bell notification icon."""
    img = Image.new('RGBA', (size, size), (255, 255, 255, 0))
    draw = ImageDraw.Draw(img)

    # Calculate bell shape (simplified)
    margin = size // 6

    # Draw bell body (simplified circle/ellipse)
    draw.ellipse(
        [margin, margin, size - margin, size - margin],
        fill=(255, 255, 255, 255)
    )

    return img

def main():
    # Get the script directory
    script_dir = Path(__file__).parent
    res_dir = script_dir / 'src' / 'main' / 'res'

    print("Creating notification icons...")
    print(f"Resource directory: {res_dir}")

    # Try to find the launcher icon
    launcher_found = False
    launcher_path = res_dir / 'mipmap-xxxhdpi' / 'launcher_icon.png'

    if launcher_path.exists():
        print(f"Found launcher icon: {launcher_path}")
        launcher_found = True

    # Create icons for each density
    for density, size in DENSITIES.items():
        output_dir = res_dir / f'drawable-{density}'
        output_dir.mkdir(parents=True, exist_ok=True)
        output_path = output_dir / 'ic_notification.png'

        if launcher_found:
            # Convert launcher icon
            icon = create_notification_icon_from_launcher(launcher_path, output_path)
            if icon:
                # Resize to appropriate size
                icon = icon.resize((size, size), Image.Resampling.LANCZOS)
        else:
            # Create simple bell icon
            icon = create_simple_bell_icon(size)

        if icon:
            icon.save(output_path, 'PNG')
            print(f"✓ Created {output_path}")

    print("\n✅ Notification icons created successfully!")
    print("\nNote: These are simple icons. For best results, create custom icons using:")
    print("Android Studio → New → Image Asset → Notification Icons")

if __name__ == '__main__':
    main()
