[Reflection.Assembly]::LoadWithPartialName("System.Drawing") | Out-Null

$iconPath = "c:\Users\Anwender\Desktop\sightseeing colector app\Projekt_1\sightseeing_collector\assets\images\App icon sightseeing collector.png"

# Öffne das Bild
$img = [System.Drawing.Image]::FromFile($iconPath)
$bitmap = New-Object System.Drawing.Bitmap($img)

Write-Host "Original: $($bitmap.Width)x$($bitmap.Height)"

# Erstelle neue Bitmap mit Transparenz
$newBitmap = New-Object System.Drawing.Bitmap($bitmap.Width, $bitmap.Height, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)

# Gehe durch jeden Pixel
for ($y = 0; $y -lt $bitmap.Height; $y++) {
    for ($x = 0; $x -lt $bitmap.Width; $x++) {
        $pixel = $bitmap.GetPixel($x, $y)
        
        # Wenn Pixel weiß oder sehr hell ist, mache ihn transparent
        if ($pixel.R -gt 200 -and $pixel.G -gt 200 -and $pixel.B -gt 200) {
            $newPixel = [System.Drawing.Color]::FromArgb(0, 255, 255, 255)
        } else {
            $newPixel = $pixel
        }
        
        $newBitmap.SetPixel($x, $y, $newPixel)
    }
}

# Speichere das neue Bild
$newBitmap.Save($iconPath, [System.Drawing.Imaging.ImageFormat]::Png)
Write-Host "Icon aktualisiert: $iconPath"

# Kopiere in alle mipmap Ordner
$destinations = @("mipmap-mdpi", "mipmap-hdpi", "mipmap-xhdpi", "mipmap-xxhdpi", "mipmap-xxxhdpi")
$basePath = "c:\Users\Anwender\Desktop\sightseeing colector app\Projekt_1\sightseeing_collector\android\app\src\main\res"

foreach ($dest in $destinations) {
    $target = "$basePath\$dest\ic_launcher.png"
    if (Test-Path $target) {
        Remove-Item $target -Force
    }
    Copy-Item $iconPath $target -Force
    Write-Host "Icon kopiert zu: $dest"
}

Write-Host "✅ Fertig!"
