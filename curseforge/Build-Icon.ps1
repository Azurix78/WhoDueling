[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
. (Join-Path $PSScriptRoot '..\scripts\Payload.ps1')
$iconPath = Join-Path $PSScriptRoot 'icon.png'
Assert-WhoDuelingPlainPath $iconPath
$bitmap = New-Object Drawing.Bitmap(512, 512)
$graphics = [Drawing.Graphics]::FromImage($bitmap)
$resources = New-Object 'Collections.Generic.List[IDisposable]'
try {
    $graphics.SmoothingMode = [Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $graphics.TextRenderingHint = [Drawing.Text.TextRenderingHint]::AntiAliasGridFit
    $graphics.Clear([Drawing.ColorTranslator]::FromHtml('#111b2b'))
    $background = New-Object Drawing.SolidBrush([Drawing.ColorTranslator]::FromHtml('#18273d'))
    $border = New-Object Drawing.Pen([Drawing.ColorTranslator]::FromHtml('#2b405c'), 4)
    $path = New-Object Drawing.Drawing2D.GraphicsPath
    $resources.Add($background); $resources.Add($border); $resources.Add($path)
    $path.AddArc(16, 16, 72, 72, 180, 90)
    $path.AddArc(424, 16, 72, 72, 270, 90)
    $path.AddArc(424, 424, 72, 72, 0, 90)
    $path.AddArc(16, 424, 72, 72, 90, 90)
    $path.CloseFigure()
    $graphics.FillPath($background, $path)
    $graphics.DrawPath($border, $path)

    $reticle = New-Object Drawing.Pen([Drawing.ColorTranslator]::FromHtml('#55d3e5'), 12)
    $reticle.StartCap = [Drawing.Drawing2D.LineCap]::Round
    $reticle.EndCap = [Drawing.Drawing2D.LineCap]::Round
    $resources.Add($reticle)
    $graphics.DrawEllipse($reticle, 152, 120, 208, 208)
    $graphics.DrawLine($reticle, 256, 84, 256, 136)
    $graphics.DrawLine($reticle, 256, 312, 256, 364)
    $graphics.DrawLine($reticle, 116, 224, 168, 224)
    $graphics.DrawLine($reticle, 344, 224, 396, 224)

    $questionFont = New-Object Drawing.Font('Segoe UI', 160, [Drawing.FontStyle]::Bold, [Drawing.GraphicsUnit]::Pixel)
    $initialsFont = New-Object Drawing.Font('Segoe UI', 56, [Drawing.FontStyle]::Bold, [Drawing.GraphicsUnit]::Pixel)
    $white = New-Object Drawing.SolidBrush([Drawing.ColorTranslator]::FromHtml('#f5f7fa'))
    $gold = New-Object Drawing.SolidBrush([Drawing.ColorTranslator]::FromHtml('#e7bb70'))
    $format = New-Object Drawing.StringFormat
    $format.Alignment = [Drawing.StringAlignment]::Center
    $format.LineAlignment = [Drawing.StringAlignment]::Center
    foreach ($resource in @($questionFont, $initialsFont, $white, $gold, $format)) { $resources.Add($resource) }
    $graphics.DrawString('?', $questionFont, $white, (New-Object Drawing.RectangleF(176, 124, 160, 196)), $format)
    $graphics.DrawString('WD', $initialsFont, $gold, (New-Object Drawing.RectangleF(116, 388, 280, 80)), $format)
    $bitmap.Save($iconPath, [Drawing.Imaging.ImageFormat]::Png)
    Write-Output "Project logo: $iconPath (512 x 512 PNG)"
}
finally {
    foreach ($resource in $resources) { $resource.Dispose() }
    $graphics.Dispose()
    $bitmap.Dispose()
}
