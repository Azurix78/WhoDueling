$ErrorActionPreference = 'Stop'
$projectRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$testRoot = Join-Path $projectRoot ('.test-output\packaging-' + [guid]::NewGuid().ToString('N'))
[IO.Directory]::CreateDirectory($testRoot) | Out-Null
$powershell = Join-Path $PSHOME 'powershell.exe'
$install = Join-Path $projectRoot 'Install-Addon.ps1'
$passed = 0
function Assert-Test([bool]$Condition, [string]$Message) {
    if (-not $Condition) { throw "FAIL: $Message" }
    $script:passed++
    Write-Output "PASS: $Message"
}
function Run-Installer([string]$Script, [string]$Target, [switch]$Preview) {
    $arguments = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $Script, '-AddOnsPath', $Target)
    if ($Preview) { $arguments += '-WhatIf' }
    $output = @(& $powershell @arguments 2>&1)
    [pscustomobject]@{ Code = $LASTEXITCODE; Output = $output -join "`n" }
}

foreach ($scriptPath in @($install, (Join-Path $projectRoot 'Build-Release.ps1'), (Join-Path $projectRoot 'scripts\Payload.ps1'), $PSCommandPath)) {
    $tokens = $null
    $parseErrors = $null
    [Management.Automation.Language.Parser]::ParseFile($scriptPath, [ref]$tokens, [ref]$parseErrors) | Out-Null
    Assert-Test ($parseErrors.Count -eq 0) "PowerShell syntax: $([IO.Path]::GetFileName($scriptPath))"
}

. (Join-Path $projectRoot 'scripts\Payload.ps1')
$payload = Get-WhoDuelingPayload -ProjectRoot $projectRoot
$addons = Join-Path $testRoot 'Game with spaces\Interface\AddOns'
[IO.Directory]::CreateDirectory($addons) | Out-Null
$other = Join-Path $addons 'OtherAddon'
[IO.Directory]::CreateDirectory($other) | Out-Null
[IO.File]::WriteAllText((Join-Path $other 'keep.txt'), 'unchanged')
$result = Run-Installer $install $addons -Preview
Assert-Test ($result.Code -eq 0 -and -not (Test-Path -LiteralPath (Join-Path $addons 'WhoDueling'))) 'WhatIf makes no installation directory'
$result = Run-Installer $install $addons
Assert-Test ($result.Code -eq 0) "Install into path with spaces: $($result.Output)"
$destination = Join-Path $addons 'WhoDueling'
Assert-Test ((Get-ChildItem -LiteralPath $destination -File).Count -eq $payload.Files.Count) 'Only distributable files installed'
foreach ($name in $payload.Files) {
    Assert-Test ((Get-FileHash -LiteralPath (Join-Path $destination $name)).Hash -eq (Get-FileHash -LiteralPath (Join-Path $payload.Source $name)).Hash) "Installed hash: $name"
}
[IO.File]::WriteAllText((Join-Path $destination 'Core.lua'), 'old version')
[IO.File]::WriteAllText((Join-Path $destination 'custom.txt'), 'keep')
$result = Run-Installer $install $addons
Assert-Test ($result.Code -eq 0 -and (Get-FileHash -LiteralPath (Join-Path $destination 'Core.lua')).Hash -eq (Get-FileHash -LiteralPath (Join-Path $payload.Source 'Core.lua')).Hash) 'Update replaces old addon files'
Assert-Test ([IO.File]::ReadAllText((Join-Path $destination 'custom.txt')) -eq 'keep') 'Update does not delete unrelated files'
Assert-Test ([IO.File]::ReadAllText((Join-Path $other 'keep.txt')) -eq 'unchanged') 'Other addons remain unchanged'
$missing = Join-Path $testRoot 'Missing AddOns'
$result = Run-Installer $install $missing
Assert-Test ($result.Code -ne 0 -and -not (Test-Path -LiteralPath $missing)) 'Missing AddOns directory fails before copying'
$result = Run-Installer $install $projectRoot
Assert-Test ($result.Code -ne 0) 'Identical source and destination are rejected'

$fixture = Join-Path $testRoot 'Incomplete project'
[IO.Directory]::CreateDirectory((Join-Path $fixture 'WhoDueling')) | Out-Null
[IO.Directory]::CreateDirectory((Join-Path $fixture 'scripts')) | Out-Null
Copy-Item -LiteralPath $install -Destination (Join-Path $fixture 'Install-Addon.ps1')
Copy-Item -LiteralPath (Join-Path $projectRoot 'scripts\Payload.ps1') -Destination (Join-Path $fixture 'scripts\Payload.ps1')
foreach ($name in $payload.Files) {
    if ($name -ne 'Core.lua') { Copy-Item -LiteralPath (Join-Path $payload.Source $name) -Destination (Join-Path $fixture 'WhoDueling') }
}
$fresh = Join-Path $testRoot 'Fresh AddOns'
[IO.Directory]::CreateDirectory($fresh) | Out-Null
$result = Run-Installer (Join-Path $fixture 'Install-Addon.ps1') $fresh
Assert-Test ($result.Code -ne 0 -and -not (Test-Path -LiteralPath (Join-Path $fresh 'WhoDueling'))) 'Missing source fails before mutation'

$junctionRoot = Join-Path $testRoot 'Junction AddOns'
$junctionTarget = Join-Path $testRoot 'Junction target'
[IO.Directory]::CreateDirectory($junctionRoot) | Out-Null
[IO.Directory]::CreateDirectory($junctionTarget) | Out-Null
New-Item -ItemType Junction -Path (Join-Path $junctionRoot 'WhoDueling') -Target $junctionTarget | Out-Null
$result = Run-Installer $install $junctionRoot
Assert-Test ($result.Code -ne 0 -and (Get-ChildItem -LiteralPath $junctionTarget).Count -eq 0) 'Junction destination is rejected without writing through it'

& (Join-Path $projectRoot 'Build-Release.ps1') | Out-Host
$zipPath = Join-Path $projectRoot "dist\WhoDueling-$($payload.Version).zip"
$zip = [IO.Compression.ZipFile]::OpenRead($zipPath)
try {
    Assert-Test ($zip.Entries.Count -eq $payload.Files.Count) 'ZIP contains only distributable files'
    foreach ($name in $payload.Files) {
        $entry = $zip.GetEntry("WhoDueling/$name")
        Assert-Test ($null -ne $entry) "ZIP entry: WhoDueling/$name"
        $stream = $entry.Open()
        try {
            $algorithm = [Security.Cryptography.SHA256]::Create()
            try { $hash = [BitConverter]::ToString($algorithm.ComputeHash($stream)).Replace('-', '') }
            finally { $algorithm.Dispose() }
            Assert-Test ($hash -eq (Get-FileHash -LiteralPath (Join-Path $payload.Source $name)).Hash) "ZIP hash: $name"
        }
        finally { $stream.Dispose() }
    }
}
finally { $zip.Dispose() }
Write-Output "$passed packaging checks passed. Fixtures: $testRoot"
