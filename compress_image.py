from PIL import Image
import os

img_path = r'assets\images\Token_gold_Speicherstadt.png'

# Öffne das Bild
img = Image.open(img_path)
print(f'Original Größe: {img.size}')
print(f'Original Dateigröße: {os.path.getsize(img_path) / 1024:.1f} KB')

# Komprimiere das Bild (max 400x400 Pixel)
img.thumbnail((400, 400), Image.Resampling.LANCZOS)

# Speichere mit Kompression
img.save(img_path, 'PNG', optimize=True)
print(f'Neue Dateigröße: {os.path.getsize(img_path) / 1024:.1f} KB')
print('Bild erfolgreich komprimiert!')
