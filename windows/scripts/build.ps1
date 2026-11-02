param([string]$OutputDirectory = '', [switch]$SkipInstaller)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$root = Split-Path $PSScriptRoot -Parent
if (!$OutputDirectory) { $OutputDirectory = Join-Path $root 'dist' }
$out = [IO.Path]::GetFullPath($OutputDirectory)
$project = Join-Path $root 'src/MacMarker.Windows/MacMarker.Windows.csproj'
$version = '0.2.0'
$base = "MacMarker-$version-windows-x64"
$app = Join-Path $out 'app'
function Assert-Exit([string]$name) { if ($LASTEXITCODE -ne 0) { throw "$name failed: exit $LASTEXITCODE" } }
if (Test-Path $app) { throw 'App output exists; use a fresh OutputDirectory. Existing files were preserved.' }
foreach ($name in @("$base.zip", "$base-setup.exe")) {
    if (Test-Path (Join-Path $out $name)) { throw 'Versioned package exists; choose a fresh OutputDirectory.' }
}
$sha = (& git -C $root rev-parse HEAD).Trim()
Assert-Exit 'Read source SHA'
if ($sha -notmatch '^[a-f0-9]{40}$') { throw 'Invalid source SHA' }
$dirty = & git -C $root status --porcelain --untracked-files=all -- . ../LICENSE
Assert-Exit 'Read source status'
if ($dirty) { throw 'Commit Windows source inputs before building release artifacts.' }
New-Item -ItemType Directory -Force $out | Out-Null
Push-Location $root
try {
    & dotnet publish $project -c Release -r win-x64 --self-contained true `
        -p:EnableWindowsTargeting=true -p:PublishSingleFile=true -p:IncludeNativeLibrariesForSelfExtract=true `
        -p:ContinuousIntegrationBuild=true -p:DebugType=None -p:DebugSymbols=false "-p:SourceRevisionId=$sha" -o $app
    Assert-Exit 'Publish self-contained Windows application'
} finally { Pop-Location }
# Resolve the exact restored Microsoft packs; never guess runtime versions or vendor legal text.
$packJson = & dotnet msbuild $project -target:ResolveFrameworkReferences -p:RuntimeIdentifier=win-x64 -p:SelfContained=true -getItem:ResolvedRuntimePack | Out-String
Assert-Exit 'Resolve runtime pack provenance'
$packs = @((ConvertFrom-Json $packJson).Items.ResolvedRuntimePack | Where-Object { $_.NuGetPackageId -in @('Microsoft.NETCore.App.Runtime.win-x64', 'Microsoft.WindowsDesktop.App.Runtime.win-x64') })
if ($packs.Count -ne 2) { throw 'Runtime provenance must contain NETCore and WindowsDesktop' }
$runtimeInfo = @($packs | ForEach-Object {
    $pack = $_
    $destination = Join-Path $app ('licenses/' + $pack.NuGetPackageId)
    New-Item -ItemType Directory -Force $destination | Out-Null
    $legal = @(Get-ChildItem $pack.PackageDirectory -File | Where-Object { $_.Name -match '^(LICENSE|THIRD-PARTY-NOTICES)' -or $_.Name -like '*.versions.txt' -or $_.Extension -eq '.nuspec' })
    if (!@($legal | Where-Object { $_.Name -match '^LICENSE' }).Count) { throw 'Restored runtime license missing' }
    $legal | Copy-Item -Destination $destination
    [ordered]@{ package = $pack.NuGetPackageId; version = $pack.NuGetPackageVersion; files = @($legal.Name) }
})
if (!(Test-Path (Join-Path $app 'licenses/Microsoft.NETCore.App.Runtime.win-x64/THIRD-PARTY-NOTICES.TXT'))) { throw 'Runtime third-party notices missing' }
@'
# Bundled Microsoft runtimes

This self-contained app includes .NET and WindowsDesktop from the restored Microsoft runtime packs identified in windows-build-manifest.json. Their original licenses, notices, version records and NuGet provenance are included unchanged under licenses/. WindowsDesktop supplies its own MIT LICENSE and no separate third-party notice file in that package. The .NET runtime third-party notices are included in full.
'@ | Set-Content (Join-Path $app 'THIRD-PARTY-NOTICES.md') -Encoding utf8
Copy-Item (Join-Path $root 'README.md') (Join-Path $app 'README.md')
Copy-Item (Join-Path $root '../LICENSE') (Join-Path $app 'LICENSE')
$exe = Join-Path $app 'MacMarker.exe'
if (!(Test-Path $exe)) { throw 'Published executable missing' }
if ($IsWindows -and (Get-Item $exe).VersionInfo.ProductVersion.Split('+')[0] -ne $version) { throw 'Executable version mismatch' }
Compress-Archive -Path (Join-Path $app '*') -DestinationPath (Join-Path $out "$base.zip") -CompressionLevel Optimal
if (!$SkipInstaller) {
    $iscc = Join-Path ${env:ProgramFiles(x86)} 'Inno Setup 6/ISCC.exe'
    if (!(Test-Path $iscc)) {
        if ($env:GITHUB_ACTIONS -ne 'true') { throw 'Inno Setup 6 required. Install it explicitly, or use -SkipInstaller; local installers are never run automatically.' }
        & choco install innosetup --yes --no-progress
        Assert-Exit 'Install Inno Setup on isolated GitHub runner'
    }
    if (!(Test-Path $iscc)) { throw 'Inno Setup compiler not found' }
    & $iscc "/DAppSource=$app" "/DOutputDir=$out" "/DAppVersion=$version" "/DPackageBaseName=$base-setup" (Join-Path $PSScriptRoot 'installer.iss')
    Assert-Exit 'Build per-user installer'
}
$names = @("$base.zip")
if (!$SkipInstaller) { $names += "$base-setup.exe" }
$artifacts = @($names | ForEach-Object {
    $file = Get-Item (Join-Path $out $_)
    [ordered]@{ name = $file.Name; bytes = $file.Length; sha256 = (Get-FileHash $file.FullName -Algorithm SHA256).Hash.ToLowerInvariant() }
})
[ordered]@{ schemaVersion = 1; version = $version; platform = 'windows-x64'; sourceSHA = $sha; sourceRoot = 'windows'; signed = $false; runtime = '.NET10 self-contained'; runtimePacks = $runtimeInfo; artifacts = $artifacts } |
    ConvertTo-Json -Depth 6 | Set-Content (Join-Path $out 'windows-build-manifest.json') -Encoding utf8
$artifacts | ForEach-Object { "$($_.sha256)  $($_.name)" } | Set-Content (Join-Path $out 'WINDOWS-SHA256SUMS') -Encoding ascii
Write-Host "Built unsigned Windows$version from $sha"
