function Get-WhoDuelingPayload {
    param([Parameter(Mandatory)][string]$ProjectRoot)
    $source = Join-Path $ProjectRoot 'WhoDueling'
    $files = @('WhoDueling.toc', 'Localization.lua', 'Logic.lua', 'Data.lua', 'UI.lua', 'Core.lua', 'README.md', 'LICENSE')
    foreach ($name in $files) {
        $file = Join-Path $source $name
        if (-not (Test-Path -LiteralPath $file -PathType Leaf)) { throw "Fichier source manquant : $file" }
        Assert-WhoDuelingPlainPath $file
    }
    $toc = Get-Content -LiteralPath (Join-Path $source 'WhoDueling.toc') -Encoding UTF8
    $versionLine = $toc | Where-Object { $_ -match '^## Version:' } | Select-Object -First 1
    if ($versionLine -notmatch '^## Version:\s*(\d+\.\d+\.\d+)\s*$') { throw 'Version absente ou invalide dans le TOC.' }
    $version = $Matches[1]
    $lua = @($toc | ForEach-Object { $_.Trim() } | Where-Object { $_ -and -not $_.StartsWith('#') })
    if (($lua -join '|') -ne 'Localization.lua|Logic.lua|Data.lua|UI.lua|Core.lua') {
        throw 'Le contenu du TOC ne correspond pas aux fichiers distribuables.'
    }
    [pscustomobject]@{ Source = [IO.Path]::GetFullPath($source); Files = $files; Version = $version }
}

function Assert-WhoDuelingPlainPath {
    param([Parameter(Mandatory)][string]$Path)
    $cursor = [IO.Path]::GetFullPath($Path)
    while ($cursor) {
        if (Test-Path -LiteralPath $cursor) {
            if ((Get-Item -LiteralPath $cursor -Force).Attributes -band [IO.FileAttributes]::ReparsePoint) {
                throw "Chemin refuse (lien ou jonction) : $cursor"
            }
        }
        $parent = [IO.Directory]::GetParent($cursor)
        $cursor = if ($parent) { $parent.FullName } else { $null }
    }
}
