[CmdletBinding(SupportsShouldProcess)]
param(
    [ValidateNotNullOrEmpty()]
    [string]$AddOnsPath = 'C:\Program Files (x86)\World of Warcraft\_classic_beta_\Interface\AddOns',
    [switch]$ElevateOnAccessDenied
)

$ErrorActionPreference = 'Stop'
try {
    . (Join-Path $PSScriptRoot 'scripts\Payload.ps1')
    $payload = Get-WhoDuelingPayload -ProjectRoot $PSScriptRoot
    if (-not (Test-Path -LiteralPath $AddOnsPath -PathType Container)) { throw "Dossier AddOns introuvable : $AddOnsPath" }
    Assert-WhoDuelingPlainPath $AddOnsPath
    $resolvedAddOns = (Resolve-Path -LiteralPath $AddOnsPath).ProviderPath
    $destination = [IO.Path]::GetFullPath((Join-Path $resolvedAddOns 'WhoDueling'))
    if ([string]::Equals($payload.Source, $destination, [StringComparison]::OrdinalIgnoreCase)) {
        throw 'Le dossier source et le dossier de destination sont identiques.'
    }
    Assert-WhoDuelingPlainPath $destination
    foreach ($name in $payload.Files) { Assert-WhoDuelingPlainPath (Join-Path $destination $name) }
    if ($PSCmdlet.ShouldProcess($destination, "Installer WhoDueling $($payload.Version)")) {
        [IO.Directory]::CreateDirectory($destination) | Out-Null
        foreach ($name in $payload.Files) {
            $sourceFile = Join-Path $payload.Source $name
            $targetFile = Join-Path $destination $name
            Copy-Item -LiteralPath $sourceFile -Destination $targetFile -Force
            if ((Get-FileHash -LiteralPath $sourceFile).Hash -ne (Get-FileHash -LiteralPath $targetFile).Hash) {
                throw "Verification echouee : $name"
            }
        }
        Write-Host "WhoDueling $($payload.Version) installe dans : $destination" -ForegroundColor Green
        Write-Host 'Premiere installation : redemarrez WoW et activez WhoDueling dans la liste des addons.'
        Write-Host 'Mise a jour : /reload si WhoDueling est deja charge et si aucun nouveau fichier n a ete ajoute.'
    }
}
catch {
    Write-Host "Installation impossible : $($_.Exception.Message)" -ForegroundColor Red
    $exception = $_.Exception
    $accessDenied = $_.CategoryInfo.Category -eq 'PermissionDenied'
    while ($exception) {
        if ($exception -is [UnauthorizedAccessException]) { $accessDenied = $true }
        $exception = $exception.InnerException
    }
    if ($accessDenied) {
        if ($ElevateOnAccessDenied -and -not $WhatIfPreference) {
            Write-Host 'Windows demande les droits administrateur. Acceptez la demande UAC pour installer WhoDueling.'
            $escapedScript = $PSCommandPath.Replace("'", "''")
            $escapedTarget = $AddOnsPath.Replace("'", "''")
            $command = "& '$escapedScript' -AddOnsPath '$escapedTarget'"
            $encoded = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($command))
            try {
                $child = Start-Process -FilePath (Join-Path $PSHOME 'powershell.exe') -Verb RunAs -WindowStyle Hidden -Wait -PassThru -ArgumentList @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-EncodedCommand', $encoded)
                if ($child.ExitCode -ne 0) { throw "Installation avec les droits administrateur echouee (code $($child.ExitCode))." }
                Write-Host 'WhoDueling installe. Redemarrez WoW apres la premiere installation.' -ForegroundColor Green
                exit 0
            }
            catch {
                Write-Host "Installation impossible ou demande administrateur annulee : $($_.Exception.Message)" -ForegroundColor Red
                exit 1
            }
        }
        Write-Host 'Ouvrez PowerShell en tant qu administrateur, puis relancez :'
        $escapedScript = $PSCommandPath.Replace("'", "''")
        $escapedTarget = $AddOnsPath.Replace("'", "''")
        Write-Host "& '$escapedScript' -AddOnsPath '$escapedTarget'"
    }
    exit 1
}
