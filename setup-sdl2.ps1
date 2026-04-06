# setup-sdl2.ps1 - Download and setup SDL2 development libraries

$SDL2_VERSION = "2.30.10"
$SDL2_URL = "https://github.com/libsdl-org/SDL/releases/download/release-$SDL2_VERSION/SDL2-devel-$SDL2_VERSION-VC.zip"
$DOWNLOAD_PATH = "$PSScriptRoot\SDL2-devel-$SDL2_VERSION-VC.zip"
$EXTRACT_PATH = "$PSScriptRoot\SDL2-$SDL2_VERSION"
$TARGET_PATH = "$PSScriptRoot\sdl2"

Write-Host "SDL2 Setup Script" -ForegroundColor Cyan
Write-Host "=================" -ForegroundColor Cyan

# Check if already setup
if (Test-Path "$TARGET_PATH\lib\x86\SDL2.dll") {
    Write-Host "SDL2 is already set up in $TARGET_PATH" -ForegroundColor Green
    exit 0
}

# Download
Write-Host "Downloading SDL2 $SDL2_VERSION..." -ForegroundColor Yellow
try {
    Invoke-WebRequest -Uri $SDL2_URL -OutFile $DOWNLOAD_PATH -UseBasicParsing
} catch {
    Write-Host "Failed to download SDL2: $_" -ForegroundColor Red
    exit 1
}

# Extract
Write-Host "Extracting..." -ForegroundColor Yellow
Expand-Archive -Path $DOWNLOAD_PATH -DestinationPath $PSScriptRoot -Force

# Create target directory structure
Write-Host "Setting up directory structure..." -ForegroundColor Yellow
New-Item -ItemType Directory -Path "$TARGET_PATH\include" -Force | Out-Null
New-Item -ItemType Directory -Path "$TARGET_PATH\lib\x86" -Force | Out-Null

# Copy files
Copy-Item -Path "$EXTRACT_PATH\include\*" -Destination "$TARGET_PATH\include\" -Recurse -Force
Copy-Item -Path "$EXTRACT_PATH\lib\x86\*" -Destination "$TARGET_PATH\lib\x86\" -Force

# Cleanup
Write-Host "Cleaning up..." -ForegroundColor Yellow
Remove-Item -Path $DOWNLOAD_PATH -Force
Remove-Item -Path $EXTRACT_PATH -Recurse -Force

Write-Host "SDL2 setup complete!" -ForegroundColor Green
Write-Host "SDL2.dll location: $TARGET_PATH\lib\x86\SDL2.dll" -ForegroundColor Cyan
