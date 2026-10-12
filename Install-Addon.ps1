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
    if (-not (Test-Path -LiteralPath $AddOnsPath -PathType Container)) { throw "AddOns directory not found: $AddOnsPath" }
    Assert-WhoDuelingPlainPath $AddOnsPath
    $resolvedAddOns = (Resolve-Path -LiteralPath $AddOnsPath).ProviderPath
    $destination = [IO.Path]::GetFullPath((Join-Path $resolvedAddOns 'WhoDueling'))
    if ([string]::Equals($payload.Source, $destination, [StringComparison]::OrdinalIgnoreCase)) {
        throw 'Source and destination directories are identical.'
    }
    Assert-WhoDuelingPlainPath $destination
    foreach ($name in $payload.Files) { Assert-WhoDuelingPlainPath (Join-Path $destination $name) }
    if ($PSCmdlet.ShouldProcess($destination, "Install WhoDueling $($payload.Version)")) {
        [IO.Directory]::CreateDirectory($destination) | Out-Null
        foreach ($name in $payload.Files) {
            $sourceFile = Join-Path $payload.Source $name
            $targetFile = Join-Path $destination $name
            Copy-Item -LiteralPath $sourceFile -Destination $targetFile -Force
            if ((Get-FileHash -LiteralPath $sourceFile).Hash -ne (Get-FileHash -LiteralPath $targetFile).Hash) {
                throw "File verification failed: $name"
            }
        }
        Write-Host "WhoDueling $($payload.Version) installed in: $destination" -ForegroundColor Green
        Write-Host 'First installation: restart WoW and enable WhoDueling in the addon list.'
        Write-Host 'Update: use /reload if WhoDueling is already loaded and no new files were added.'
    }
}
catch {
    Write-Host "Installation failed: $($_.Exception.Message)" -ForegroundColor Red
    $exception = $_.Exception
    $accessDenied = $_.CategoryInfo.Category -eq 'PermissionDenied'
    while ($exception) {
        if ($exception -is [UnauthorizedAccessException]) { $accessDenied = $true }
        $exception = $exception.InnerException
    }
    if ($accessDenied) {
        if ($ElevateOnAccessDenied -and -not $WhatIfPreference) {
            Write-Host 'Windows requires administrator privileges. Accept the UAC prompt to install WhoDueling.'
            $escapedScript = $PSCommandPath.Replace("'", "''")
            $escapedTarget = $AddOnsPath.Replace("'", "''")
            $command = "& '$escapedScript' -AddOnsPath '$escapedTarget'"
            $encoded = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($command))
            try {
                $child = Start-Process -FilePath (Join-Path $PSHOME 'powershell.exe') -Verb RunAs -WindowStyle Hidden -Wait -PassThru -ArgumentList @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-EncodedCommand', $encoded)
                if ($child.ExitCode -ne 0) { throw "Administrator installation failed (exit code $($child.ExitCode))." }
                Write-Host 'WhoDueling installed. Restart WoW after the first installation.' -ForegroundColor Green
                exit 0
            }
            catch {
                Write-Host "Installation failed or administrator prompt cancelled: $($_.Exception.Message)" -ForegroundColor Red
                exit 1
            }
        }
        Write-Host 'Open PowerShell as administrator, then run:'
        $escapedScript = $PSCommandPath.Replace("'", "''")
        $escapedTarget = $AddOnsPath.Replace("'", "''")
        Write-Host "& '$escapedScript' -AddOnsPath '$escapedTarget'"
    }
    exit 1
}
