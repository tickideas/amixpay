$ndkBin = "C:\Users\mcjam\AppData\Local\Android\Sdk\ndk\28.2.13676358\toolchains\llvm\prebuilt\windows-x86_64\bin"
$flutterBin = "C:\Users\mcjam\Documents\APP BUILD 2026\flutter_windows_3.41.4-stable\flutter\bin"
$env:PATH = "$ndkBin;$flutterBin;$env:PATH"
Write-Host "Testing llvm-strip access..."
& "$ndkBin\llvm-strip.exe" --version
Write-Host "PATH includes NDK: $($env:PATH -match 'ndk')"
Set-Location "C:\Users\mcjam\Documents\APP BUILD 2026\AmixPAY"
Write-Host "Building with verbose..."
& "$flutterBin\flutter.bat" build appbundle --release --verbose 2>&1 | Select-String -Pattern "strip|error|Error|FAILED|failed" -CaseSensitive:$false
