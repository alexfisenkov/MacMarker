param([Parameter(Mandatory)][string]$Installer, [Parameter(Mandatory)][string]$Receipt, [switch]$CiDesktop)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
if (!$CiDesktop -or $env:CI -ne 'true') { throw 'Installer smoke is allowed only on an isolated CI desktop with -CiDesktop and CI=true.' }
$installerPath = (Resolve-Path $Installer).Path
$receiptPath = [IO.Path]::GetFullPath($Receipt)
$temporary = Join-Path ([IO.Path]::GetTempPath()) ('MacMarker-InstallSmoke-' + [Guid]::NewGuid().ToString('N'))
$install = Join-Path $temporary 'application'
$settings = Join-Path $temporary 'preferences'
New-Item -ItemType Directory -Force $temporary, (Split-Path $receiptPath) | Out-Null
$installed = $false
try {
    $setup = Start-Process $installerPath -ArgumentList @('/CURRENTUSER', '/VERYSILENT', '/SUPPRESSMSGBOXES', '/NORESTART', '/SP-', ('/DIR="' + $install + '"')) -PassThru -Wait
    if ($setup.ExitCode -ne 0) { throw "Installer failed: exit$($setup.ExitCode)" }
    $installed = $true
    $exe = Join-Path $install 'MacMarker.exe'
    if (!(Test-Path $exe)) { throw 'Installed executable missing' }
    $nativeReceipt = Join-Path $temporary 'installed-native.json'
    & (Join-Path $PSScriptRoot 'smoke.ps1') -Executable $exe -Receipt $nativeReceipt -SettingsDirectory $settings -CiDesktop
    $native = Get-Content $nativeReceipt -Raw | ConvertFrom-Json
    $manifestPath = Join-Path (Split-Path $installerPath) 'windows-build-manifest.json'
    if (Test-Path $manifestPath) {
        $manifest = Get-Content $manifestPath -Raw | ConvertFrom-Json
        if ($native.sourceVersion -ne ($manifest.version + '+' + $manifest.sourceSHA)) { throw 'Installed source identity differs from build manifest' }
    }
    $preferences = Join-Path $settings 'settings.json'
    $before = (Get-FileHash $preferences).Hash
    $uninstall = Join-Path $install 'unins000.exe'
    $process = Start-Process $uninstall -ArgumentList @('/VERYSILENT', '/SUPPRESSMSGBOXES', '/NORESTART') -PassThru -Wait
    if ($process.ExitCode -ne 0) { throw "Uninstaller failed: exit$($process.ExitCode)" }
    $installed = $false
    Start-Sleep -Milliseconds 500
    if (Test-Path $exe) { throw 'Uninstaller left the application executable' }
    if (!(Test-Path $preferences) -or (Get-FileHash $preferences).Hash -ne $before) { throw 'Uninstaller modified preserved preferences' }
    [ordered]@{ schemaVersion = 1; pass = $true; perUserSilentInstall = $true; installedNativeSmoke = $native; uninstalled = $true; preferencesPreserved = $true; signed = $false; physicalHardwareAcceptance = 'NOT_RUN' } |
        ConvertTo-Json -Depth 12 | Set-Content $receiptPath -Encoding utf8
    Write-Host 'PASS per-user install/native firstlaunch/uninstall/preferences preservation'
} catch {
    [ordered]@{ schemaVersion = 1; pass = $false; error = $_.Exception.Message } | ConvertTo-Json | Set-Content $receiptPath -Encoding utf8
    throw
} finally {
    if ($installed -and (Test-Path (Join-Path $install 'unins000.exe'))) {
        Start-Process (Join-Path $install 'unins000.exe') -ArgumentList @('/VERYSILENT', '/SUPPRESSMSGBOXES', '/NORESTART') -Wait | Out-Null
    }
    if (Test-Path $temporary) { Remove-Item $temporary -Recurse -Force }
}
