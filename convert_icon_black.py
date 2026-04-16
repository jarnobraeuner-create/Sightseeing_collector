#!/usr/bin/env python3
"""
Dieses Script ersetzt den weißen Hintergrund im App Icon durch schwarz
"""
from PIL import Image
import os

iconPath = r'c:\Users\Anwender\Desktop\sightseeing colector app\Projekt_1\sightseeing_collector\assets\images\App icon sightseeing collector.png'

# Prüfe ob Datei existiert
if not os.path.exists(iconPath):
    print(f"Fehler: Datei nicht gefunden: {iconPath}")
    exit(1)

# Öffne das Bild
img = Image.open(iconPath)
print(f"Bildmodus: {img.mode}, Größe: {img.size}")

# Konvertiere zu RGB wenn notwendig
if img.mode in ['RGBA', 'LA', 'P']:
    # Erstelle weißen Hintergrund
    background = Image.new('RGB', img.size, (0, 0, 0))  # Schwarz
    if img.mode == 'P':
        img = img.convert('RGBA')
    background.paste(img, mask=img.split()[-1] if img.mode == 'RGBA' else None)
    img = background
elif img.mode != 'RGB':
    img = img.convert('RGB')

# Gehe durch jeden Pixel und ersetze Weiß mit Schwarz
pixels = img.load()
width, height = img.size

for y in range(height):
    for x in range(width):
        r, g, b = pixels[x, y][:3] if len(pixels[x, y]) >= 3 else pixels[x, y]
        # Wenn sehr hell (weiß oder grau), mache es dunkelgrau/schwarz
        if r > 200 and g > 200 and b > 200:
            pixels[x, y] = (20, 20, 20)

# Speichere das Bild
img.save(iconPath, 'PNG')
print(f"✅ Icon aktualisiert (Weiß → Schwarz): {iconPath}")

# Kopiere in alle mipmap-Ordner
destinations = ['mipmap-mdpi', 'mipmap-hdpi', 'mipmap-xhdpi', 'mipmap-xxhdpi', 'mipmap-xxxhdpi']
basePath = r'c:\Users\Anwender\Desktop\sightseeing colector app\Projekt_1\sightseeing_collector\android\app\src\main\res'

for dest in destinations:
    target = os.path.join(basePath, dest, 'ic_launcher.png')
    try:
        if os.path.exists(target):
            os.remove(target)
        img.save(target, 'PNG')
        print(f"✅ Kopiert zu {dest}")
    except Exception as e:
        print(f"❌ Fehler bei {dest}: {e}")

print("✅ Fertig!")
