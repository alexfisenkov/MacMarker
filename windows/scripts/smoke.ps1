param(
    [Parameter(Mandatory)][string]$Executable,
    [Parameter(Mandatory)][string]$Receipt,
    [string]$SettingsDirectory = '',
    [switch]$CiDesktop
)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
if (!$CiDesktop -or $env:CI -ne 'true') { throw 'Native SendInput smoke requires -CiDesktop and CI=true on an isolated CI desktop.' }
$exe = (Resolve-Path $Executable).Path
$receiptPath = [IO.Path]::GetFullPath($Receipt)
$temporary = Join-Path ([IO.Path]::GetTempPath()) ('MacMarker-Smoke-' + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force $temporary, (Split-Path $receiptPath) | Out-Null
$packaged = $false
$manifestPath = Join-Path (Split-Path (Split-Path $exe)) 'windows-build-manifest.json'
$zip = Join-Path (Split-Path (Split-Path $exe)) 'MacMarker-0.2.0-windows-x64.zip'
if (Test-Path $zip) {
    $unpacked = Join-Path $temporary 'portable'
    Expand-Archive $zip $unpacked
    $portableExe = Join-Path $unpacked 'MacMarker.exe'
    if ((Get-FileHash $portableExe).Hash -ne (Get-FileHash $exe).Hash) { throw 'Portable package differs from published executable' }
    $exe = $portableExe; $packaged = $true
}
if (!$SettingsDirectory) { $SettingsDirectory = Join-Path $temporary 'settings' }
$SettingsDirectory = [IO.Path]::GetFullPath($SettingsDirectory)
if (Test-Path (Join-Path $SettingsDirectory 'settings.json')) { throw 'Smoke requires fresh isolated preferences, never real user preferences.' }
$names = @('MACMARKER_CI_SMOKE', 'MACMARKER_SETTINGS_DIR', 'DOTNET_BUNDLE_EXTRACT_BASE_DIR')
$old = @{}; foreach ($name in $names) { $old[$name] = [Environment]::GetEnvironmentVariable($name) }
try {
    $env:MACMARKER_CI_SMOKE = '1'; $env:MACMARKER_SETTINGS_DIR = $SettingsDirectory
    $env:DOTNET_BUNDLE_EXTRACT_BASE_DIR = Join-Path $temporary 'runtime'
    $process = Start-Process $exe -ArgumentList @('--smoke-test', ('"' + $receiptPath + '"')) -PassThru
    if (!$process.WaitForExit(60000)) { $process.Kill(); throw 'Native smoke timed out; process terminated to release hooks.' }
    if ($process.ExitCode -ne 0) {
        if (Test-Path $receiptPath) { Get-Content $receiptPath -Raw | Write-Host }
        throw "Native smoke failed: exit$($process.ExitCode)"
    }
    if (!(Test-Path $receiptPath)) { throw 'Native receipt missing' }
    $result = Get-Content $receiptPath -Raw | ConvertFrom-Json
    if (!$result.pass) { throw 'Native assertions failed' }
    if (Test-Path $manifestPath) {
        $manifest = Get-Content $manifestPath -Raw | ConvertFrom-Json
        if ($result.sourceVersion -ne ($manifest.version + '+' + $manifest.sourceSHA)) { throw 'Native source identity differs from build manifest' }
    }
    $result | Add-Member -NotePropertyName portableZipExecuted -NotePropertyValue $packaged
    $result | ConvertTo-Json -Depth 10 | Set-Content $receiptPath -Encoding utf8
    Write-Host 'PASS native tray/settings/SendInput/hold/fade/pause smoke'
} finally {
    foreach ($name in $names) { [Environment]::SetEnvironmentVariable($name, $old[$name]) }
    if (Test-Path $temporary) { Remove-Item $temporary -Recurse -Force }
}
