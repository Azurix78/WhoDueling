[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'scripts\Payload.ps1')
$payload = Get-WhoDuelingPayload -ProjectRoot $PSScriptRoot
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
$releaseDirectory = Join-Path $PSScriptRoot 'dist'
Assert-WhoDuelingPlainPath $releaseDirectory
[IO.Directory]::CreateDirectory($releaseDirectory) | Out-Null
$releasePath = Join-Path $releaseDirectory "WhoDueling-$($payload.Version).zip"
Assert-WhoDuelingPlainPath $releasePath
$stream = [IO.File]::Open($releasePath, [IO.FileMode]::Create)
try {
    $zip = New-Object IO.Compression.ZipArchive($stream, [IO.Compression.ZipArchiveMode]::Create, $true)
    try {
        foreach ($name in $payload.Files) {
            [IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, (Join-Path $payload.Source $name),
                "WhoDueling/$name", [IO.Compression.CompressionLevel]::Optimal) | Out-Null
        }
    }
    finally { $zip.Dispose() }
}
finally { $stream.Dispose() }
Write-Output "Upload archive: $releasePath"
Write-Output "SHA256: $((Get-FileHash -LiteralPath $releasePath -Algorithm SHA256).Hash)"
