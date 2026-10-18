# Builds the Windows app, then a .zip (used by the in-app updater)
# and an Inno Setup installer.
# Usage: ./windows/ci/build.ps1 -Arch x64 -Zip laststats-windows.zip
param(
  [Parameter(Mandatory = $true)][ValidateSet('x64', 'arm64')][string]$Arch,
  [Parameter(Mandatory = $true)][string]$Zip
)
$ErrorActionPreference = 'Stop'

# No version given = dev build: never claim to be a real release
$run = if ($env:RUN_NUMBER) { $env:RUN_NUMBER } else { '0' }
$version = if ($env:APP_VERSION) { $env:APP_VERSION } else { "0.0.0-dev.$run" }

flutter build windows --release --build-name="$version" --build-number=$run
if ($LASTEXITCODE -ne 0) { throw 'flutter build failed' }

# The \* puts the files directly in the zip, not in a "Release" folder
Compress-Archive -Path "build/windows/$Arch/runner/Release/*" -DestinationPath $Zip -Force

# Installer (Inno Setup reads the version from APP_VERSION)
choco install innosetup -y --no-progress
$env:APP_VERSION = $version
& 'C:\Program Files (x86)\Inno Setup 6\ISCC.exe' windows\installer.iss "/DMyArch=$Arch"
if ($LASTEXITCODE -ne 0) { throw 'Inno Setup failed' }
