#!/usr/bin/env python3
from PIL import Image
import os

# Pfad zum Icon
icon_path = r'c:\Users\Anwender\Desktop\sightseeing colector app\Projekt_1\sightseeing_collector\assets\images\App icon sightseeing collector.png'

# Öffne das Bild
img = Image.open(icon_path)
print(f"Original Modus: {img.mode}, Größe: {img.size}")

# Konvertiere zu RGBA
img = img.convert('RGBA')

# Hole die Bilddaten
data = img.getdata()
newData = []

# Ersetze helle Pixel (Weiß/Grau) mit Transparenz
for item in data:
    # Wenn Pixel weiß oder sehr hell ist (RGB > 200), mache ihn transparent
    if item[0] > 200 and item[1] > 200 and item[2] > 200:
        # Transparent
        newData.append((255, 255, 255, 0))
    else:
        newData.append(item)

# Setze die neuen Daten
img.putdata(newData)

# Speichere das Bild
img.save(icon_path, 'PNG')
print(f"Icon aktualisiert: {icon_path}")

# Kopiere es in alle mipmap Ordner
destinations = ['mipmap-mdpi', 'mipmap-hdpi', 'mipmap-xhdpi', 'mipmap-xxhdpi', 'mipmap-xxxhdpi']
base_path = r'c:\Users\Anwender\Desktop\sightseeing colector app\Projekt_1\sightseeing_collector\android\app\src\main\res'

for dest in destinations:
    target = os.path.join(base_path, dest, 'ic_launcher.png')
    # Lösche alte Datei
    if os.path.exists(target):
        os.remove(target)
    # Kopiere neue Datei
    img.save(target, 'PNG')
    print(f"Icon kopiert zu: {dest}")

print("✅ Fertig! Weißer Hintergrund entfernt und Icon aktualisiert.")
