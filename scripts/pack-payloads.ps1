# Pack all scripts/ghostlock/*.sh into Unix-LF tarballs under scripts/ghostlock/out/
# ready to pass to GhostLock's root.ps1 / root.bat.
$ErrorActionPreference = 'Stop'

$srcDir = Join-Path $PSScriptRoot 'ghostlock'
$outDir = Join-Path $srcDir 'out'
$stageDir = Join-Path $outDir '_stage'

New-Item -ItemType Directory -Force -Path $outDir | Out-Null
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)

Get-ChildItem -Path $srcDir -Filter '*.sh' | ForEach-Object {
    $name = $_.BaseName
    $tarPath = Join-Path $outDir "$name.tar"
    if (Test-Path $stageDir) { Remove-Item -Recurse -Force $stageDir }
    New-Item -ItemType Directory -Force -Path $stageDir | Out-Null

    $lfContent = ([System.IO.File]::ReadAllText($_.FullName, $utf8NoBom)).Replace("`r`n", "`n")
    $staged = Join-Path $stageDir $_.Name
    [System.IO.File]::WriteAllText($staged, $lfContent, $utf8NoBom)

    Push-Location $stageDir
    try {
        tar -cf $tarPath $_.Name
    } finally {
        Pop-Location
    }
    Write-Host "Packed $tarPath"
}

if (Test-Path $stageDir) { Remove-Item -Recurse -Force $stageDir }
