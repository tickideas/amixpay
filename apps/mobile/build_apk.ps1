$ndkBin = "C:\Users\mcjam\AppData\Local\Android\Sdk\ndk\28.2.13676358\toolchains\llvm\prebuilt\windows-x86_64\bin"
$flutterBin = "C:\Users\mcjam\Documents\APP BUILD 2026\flutter_windows_3.41.4-stable\flutter\bin"
$env:PATH = "$ndkBin;$flutterBin;$env:PATH"
Write-Host "NDK bin and Flutter added to PATH"
Set-Location "C:\Users\mcjam\Documents\APP BUILD 2026\AmixPAY"
Write-Host "Building release APK..."
& "$flutterBin\flutter.bat" build apk --release
Write-Host "Exit code: $LASTEXITCODE"
