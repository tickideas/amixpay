# Download and install Android SDK cmdline-tools
$sdkRoot = "C:\Users\mcjam\AppData\Local\Android\Sdk"
$cmdlineToolsUrl = "https://dl.google.com/android/repository/commandlinetools-win-11076708_latest.zip"
$downloadPath = "$env:TEMP\cmdline-tools.zip"
$extractPath = "$env:TEMP\cmdline-tools-extract"

Write-Host "Downloading cmdline-tools..."
Invoke-WebRequest -Uri $cmdlineToolsUrl -OutFile $downloadPath -UseBasicParsing

Write-Host "Extracting..."
if (Test-Path $extractPath) { Remove-Item $extractPath -Recurse -Force }
Expand-Archive -Path $downloadPath -DestinationPath $extractPath

# cmdline-tools must be placed at $ANDROID_HOME/cmdline-tools/latest/
$targetDir = "$sdkRoot\cmdline-tools\latest"
if (Test-Path $targetDir) { Remove-Item $targetDir -Recurse -Force }
New-Item -ItemType Directory -Path "$sdkRoot\cmdline-tools" -Force | Out-Null
Move-Item "$extractPath\cmdline-tools" $targetDir

Write-Host "cmdline-tools installed at: $targetDir"
Write-Host "Contents:"
Get-ChildItem "$targetDir\bin" | Select-Object Name
