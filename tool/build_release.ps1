<#
.SYNOPSIS
    Builds a Flutter Android app (split APKs, one universal APK, or an App
    Bundle), names the files, and writes a SHA-256 checksum file for each one.

.DESCRIPTION
    Steps, in order:
      1. Read the version from pubspec.yaml (for 2.8.0+38: 2.8.0 and 38).
      2. Run flutter build with the chosen flavor, mode and flags.
      3. Rename each output to
         <Name>-[<abi>-]v<version>_<build>-<flavor>-<mode>.<apk|aab>.
      4. Delete the .sha1 files Flutter writes next to APKs (Flutter has no
         SHA-256 option, and it writes them after Gradle ends, so this has to
         happen here and not in Gradle).
      5. Write <file>.sha256 in the standard sha256sum format:
         "<lower-case hash>  <file name>".
      6. Stop the Gradle daemons.

    The script writes only inside build/. Signing is done by Gradle from
    android/key.properties, as before; this script never reads that file.
    It has no app name built in, so it can be copied to other apps.

.PARAMETER Name
    Base name for the output files. Required.

.PARAMETER Target
    apk = APKs (split per ABI unless -NoSplit). aab = App Bundle.

.PARAMETER Flavor
    prod (default) or dev.

.PARAMETER Mode
    release (default), profile or debug.

.PARAMETER NoSplit
    APK only: build one universal APK instead of one per ABI.

.PARAMETER NoObfuscate
    Leave out --obfuscate and --split-debug-info. Refused for prod release.

.PARAMETER SymbolsDir
    Where --split-debug-info writes symbols. Default:
    aab: build/symbols/android-<flavor>-<version>/
    apk: build/symbols/android-<flavor>-<version>-apk/
    (separate folders, so one build never overwrites the other's symbols).

.EXAMPLE
    .\tool\build_release.ps1 -Name SreerajP_ImgVid_Gallery -Target aab

.EXAMPLE
    .\tool\build_release.ps1 -Name SreerajP_ImgVid_Gallery -Target apk -Flavor dev -Mode debug
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[A-Za-z0-9._-]+$')]
    [string]$Name,

    [Parameter(Mandatory = $true)]
    [ValidateSet('apk', 'aab')]
    [string]$Target,

    [ValidateSet('prod', 'dev')]
    [string]$Flavor = 'prod',

    [ValidateSet('release', 'profile', 'debug')]
    [string]$Mode = 'release',

    [switch]$NoSplit,

    [switch]$NoObfuscate,

    [string]$SymbolsDir
)

$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
Set-Location $repoRoot

# --- Check the options -------------------------------------------------------
if ($NoObfuscate -and $Flavor -eq 'prod' -and $Mode -eq 'release') {
    throw 'A prod release must be obfuscated. -NoObfuscate is refused for -Flavor prod -Mode release.'
}
if ($SymbolsDir -and ($NoObfuscate -or $Mode -eq 'debug')) {
    throw '-SymbolsDir is only used when the build is obfuscated (not with -NoObfuscate or -Mode debug).'
}
if ($NoSplit -and $Target -eq 'aab') {
    Write-Host '-NoSplit has no effect for an App Bundle; ignoring it.' -ForegroundColor Yellow
}
$obfuscate = -not $NoObfuscate
if ($Mode -eq 'debug' -and $obfuscate) {
    Write-Host 'Debug build: --obfuscate and --split-debug-info are left out (Flutter does not support them in debug).' -ForegroundColor Yellow
    $obfuscate = $false
}
$splitPerAbi = ($Target -eq 'apk') -and (-not $NoSplit)

# --- 1. Version from pubspec.yaml -------------------------------------------
$versionLine = Select-String -Path (Join-Path $repoRoot 'pubspec.yaml') `
    -Pattern '^version:\s*(\d+\.\d+\.\d+)\+(\d+)\s*$' | Select-Object -First 1
if (-not $versionLine) {
    throw "Could not read 'version: x.y.z+n' from pubspec.yaml. The build number (+n) is needed for the file name."
}
$version = $versionLine.Matches[0].Groups[1].Value
$buildNumber = $versionLine.Matches[0].Groups[2].Value
$versionTag = "v${version}_$buildNumber"
$suffix = "$Flavor-$Mode"
Write-Host "Building $Flavor $Mode $Target for version $version (build $buildNumber)" -ForegroundColor Cyan

# Flutter ABI name -> short name used in our file names.
$abiShortNames = [ordered]@{
    'armeabi-v7a' = 'armeabi'
    'arm64-v8a'   = 'arm64'
    'x86_64'      = 'x86_64'
}

$apkDir = Join-Path $repoRoot 'build\app\outputs\flutter-apk'
# Gradle names the bundle folder <flavor><Mode>, for example prodRelease.
$modeTitle = $Mode.Substring(0, 1).ToUpperInvariant() + $Mode.Substring(1)
$aabDir = Join-Path $repoRoot "build\app\outputs\bundle\$Flavor$modeTitle"

# Each entry: the file Flutter writes, and the name we give it.
$outputs = @()
if ($Target -eq 'apk' -and $splitPerAbi) {
    foreach ($abi in $abiShortNames.Keys) {
        $outputs += [pscustomobject]@{
            Source = Join-Path $apkDir "app-$abi-$suffix.apk"
            Final  = Join-Path $apkDir "$Name-$($abiShortNames[$abi])-$versionTag-$suffix.apk"
        }
    }
} elseif ($Target -eq 'apk') {
    $outputs += [pscustomobject]@{
        Source = Join-Path $apkDir "app-$suffix.apk"
        Final  = Join-Path $apkDir "$Name-$versionTag-$suffix.apk"
    }
} else {
    $outputs += [pscustomobject]@{
        Source = Join-Path $aabDir "app-$suffix.aab"
        Final  = Join-Path $aabDir "$Name-$versionTag-$suffix.aab"
    }
}

# Remove any old Flutter-named output first, so a stale file from an earlier
# build can never be renamed and hashed as if it were this build.
foreach ($o in $outputs) {
    Remove-Item -LiteralPath $o.Source, "$($o.Source).sha1" -ErrorAction SilentlyContinue
}

# --- Flutter arguments --------------------------------------------------------
$flutterArgs = @('build')
$flutterArgs += $(if ($Target -eq 'apk') { 'apk' } else { 'appbundle' })
$flutterArgs += @('--flavor', $Flavor, "--$Mode")
if ($obfuscate) {
    if (-not $SymbolsDir) {
        $SymbolsDir = if ($Target -eq 'apk') {
            "build/symbols/android-$Flavor-$version-apk/"
        } else {
            "build/symbols/android-$Flavor-$version/"
        }
    }
    $flutterArgs += @('--obfuscate', "--split-debug-info=$SymbolsDir")
}
if ($splitPerAbi) {
    $flutterArgs += '--split-per-abi'
}

try {
    # --- 2. Build -------------------------------------------------------------
    Write-Host "flutter $($flutterArgs -join ' ')" -ForegroundColor DarkGray
    & flutter @flutterArgs
    if ($LASTEXITCODE -ne 0) {
        throw "flutter build failed (exit code $LASTEXITCODE). Nothing was renamed or hashed."
    }

    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    $results = @()

    foreach ($o in $outputs) {
        if (-not (Test-Path -LiteralPath $o.Source)) {
            throw "Expected build output not found: $($o.Source)"
        }

        # --- 3. Rename ----------------------------------------------------------
        if (Test-Path -LiteralPath $o.Final) {
            Write-Host "Replacing existing $(Split-Path $o.Final -Leaf)" -ForegroundColor Yellow
            Remove-Item -LiteralPath $o.Final, "$($o.Final).sha256" -ErrorAction SilentlyContinue
        }
        Move-Item -LiteralPath $o.Source -Destination $o.Final

        # --- 4. Delete Flutter's .sha1 -----------------------------------------
        Remove-Item -LiteralPath "$($o.Source).sha1" -ErrorAction SilentlyContinue

        # --- 5. Write .sha256 ---------------------------------------------------
        $fileName = Split-Path $o.Final -Leaf
        $hash = (Get-FileHash -LiteralPath $o.Final -Algorithm SHA256).Hash.ToLowerInvariant()
        [System.IO.File]::WriteAllText("$($o.Final).sha256", "$hash  $fileName`n", $utf8NoBom)

        $results += [pscustomobject]@{
            File    = $fileName
            SizeMB  = [math]::Round((Get-Item -LiteralPath $o.Final).Length / 1MB, 1)
            SHA256  = $hash
        }
    }

    Write-Host ''
    Write-Host "Done. Files are in $(Split-Path $outputs[0].Final -Parent)" -ForegroundColor Green
    if ($obfuscate) {
        Write-Host "Debug symbols: $SymbolsDir (archive this folder)" -ForegroundColor Green
    }
    $results | Format-Table -AutoSize | Out-String -Width 300 | Write-Host
}
finally {
    # --- 6. Stop Gradle daemons -------------------------------------------------
    $gradlew = Join-Path $repoRoot 'android\gradlew.bat'
    if (Test-Path -LiteralPath $gradlew) {
        Write-Host 'Stopping Gradle daemons...' -ForegroundColor DarkGray
        Push-Location (Join-Path $repoRoot 'android')
        try { & $gradlew --stop | Out-Null } finally { Pop-Location }
    }
}
