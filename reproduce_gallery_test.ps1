$adb = "C:\Users\jerry\AppData\Local\Android\sdk\platform-tools\adb.exe"

# Get device size
$sizeRaw = & $adb shell wm size
$sizeRaw = $sizeRaw -replace "`r","" -replace "`n",""
if ($sizeRaw -match 'Physical size:\s*(\d+)x(\d+)') {
  $w=[int]$matches[1]; $h=[int]$matches[2]
} elseif ($sizeRaw -match '(\d+)x(\d+)') {
  $w=[int]$matches[1]; $h=[int]$matches[2]
} else {
  Write-Host "Could not parse size: $sizeRaw"
  exit 3
}
Write-Host "Device size: ${w}x${h}"

# Compute coordinates for taps (approximate)
$navY = [int]($h - [math]::Max(72, [math]::Round($h*0.06)))
$leftX = [int]([math]::Round($w*0.125))
$midLeftX = [int]([math]::Round($w*0.375))
$midRightX = [int]([math]::Round($w*0.625))
$rightX = [int]([math]::Round($w*0.875))
$centerX=[int]([math]::Round($w*0.5))
Write-Host "tap coords bottom nav (left,midLeft,midRight,right): $leftX,$navY  $midLeftX,$navY  $midRightX,$navY  $rightX,$navY"

# Start app fresh and clear logs
& $adb shell am start -S -n com.sightseeing.collector/.MainActivity
Start-Sleep -Seconds 1
& $adb logcat -c
Start-Sleep -Milliseconds 300

# Open collection tab by tapping the 3rd bottom item (index 2)
& $adb shell input tap $midRightX $navY
Start-Sleep -Seconds 1
& $adb shell screencap -p /sdcard/screen_gallery_open.png
& $adb pull /sdcard/screen_gallery_open.png .\screen_gallery_open.png | Out-Null
Write-Host 'Pulled screen_gallery_open.png'

# Press BACK (simulate tapping back-arrow or back key)
& $adb shell input keyevent 4
Start-Sleep -Seconds 1
& $adb shell screencap -p /sdcard/screen_after_back.png
& $adb pull /sdcard/screen_after_back.png .\screen_after_back.png | Out-Null
Write-Host 'Pulled screen_after_back.png'

# Ensure we are back on Explore: tap left bottom icon (index 0)
& $adb shell input tap $leftX $navY
Start-Sleep -Seconds 1

# Attempt to collect two tokens by tapping two list positions in the Explore list
$tap1Y = [int]([math]::Round($h*0.35))
$tap2Y = [int]([math]::Round($h*0.5))
Write-Host "Attempting taps at: $centerX,$tap1Y and $centerX,$tap2Y"
& $adb shell input tap $centerX $tap1Y
Start-Sleep -Seconds 1
& $adb shell input tap $centerX $tap2Y
Start-Sleep -Seconds 1

# capture result screenshots
& $adb shell screencap -p /sdcard/screen_after_collects.png
& $adb pull /sdcard/screen_after_collects.png .\screen_after_collects.png | Out-Null
Write-Host 'Pulled screen_after_collects.png'

# Collect logs (dump)
& $adb shell logcat -d > .\adb_log_after_test.txt
Write-Host 'Pulled logcat to adb_log_after_test.txt'
Write-Host 'Script finished.'
