@echo off
echo Setting up test audio files for RetrosicaV2...

REM Create the mp3 directory on device
adb shell "mkdir -p /sdcard/Android/data/com.example.retrosicav2/files/Documents/mp3"

REM Check if directory was created
adb shell "ls -la /sdcard/Android/data/com.example.retrosicav2/files/Documents/"

echo.
echo Directory created! Now copy some .mp3 files to test:
echo adb push "path\to\your\audio.mp3" "/sdcard/Android/data/com.example.retrosicav2/files/Documents/mp3/"
echo.
echo Or you can copy files manually using a file manager app on your device.
echo Target folder: Android/data/com.example.retrosicav2/files/Documents/mp3/
pause