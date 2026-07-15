Add-Type -AssemblyName System.Drawing

$size = 1024
$bmp = New-Object System.Drawing.Bitmap($size, $size)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
$g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic

$radius = 220

# --- Background: amber gradient (matching website) ---
$rectPath = New-Object System.Drawing.Drawing2D.GraphicsPath
$rectPath.AddArc(0, 0, $radius * 2, $radius * 2, 180, 90)
$rectPath.AddArc($size - $radius * 2, 0, $radius * 2, $radius * 2, 270, 90)
$rectPath.AddArc($size - $radius * 2, $size - $radius * 2, $radius * 2, $radius * 2, 0, 90)
$rectPath.AddArc(0, $size - $radius * 2, $radius * 2, $radius * 2, 90, 90)
$rectPath.CloseFigure()

$bgBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
    (New-Object System.Drawing.Point(0, 0)),
    (New-Object System.Drawing.Point($size, $size)),
    [System.Drawing.Color]::FromArgb(245, 158, 11),
    [System.Drawing.Color]::FromArgb(234, 88, 12)
)
$g.FillPath($bgBrush, $rectPath)

# --- Subtle circuit lines for futuristic feel ---
$linePen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(40, 255, 255, 255), 2)
# Horizontal lines
$g.DrawLine($linePen, 80, 200, 350, 200)
$g.DrawLine($linePen, 694, 200, 944, 200)
$g.DrawLine($linePen, 80, 824, 350, 824)
$g.DrawLine($linePen, 694, 824, 944, 824)
# Vertical lines
$g.DrawLine($linePen, 200, 80, 200, 300)
$g.DrawLine($linePen, 824, 80, 824, 300)
$g.DrawLine($linePen, 200, 724, 200, 944)
$g.DrawLine($linePen, 824, 724, 824, 944)
# Small dots at endpoints
$dotBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(50, 255, 255, 255))
$dotSize = 8
$g.FillEllipse($dotBrush, 350 - $dotSize/2, 200 - $dotSize/2, $dotSize, $dotSize)
$g.FillEllipse($dotBrush, 694 - $dotSize/2, 200 - $dotSize/2, $dotSize, $dotSize)
$g.FillEllipse($dotBrush, 200 - $dotSize/2, 300 - $dotSize/2, $dotSize, $dotSize)
$g.FillEllipse($dotBrush, 824 - $dotSize/2, 300 - $dotSize/2, $dotSize, $dotSize)
$g.FillEllipse($dotBrush, 350 - $dotSize/2, 824 - $dotSize/2, $dotSize, $dotSize)
$g.FillEllipse($dotBrush, 694 - $dotSize/2, 824 - $dotSize/2, $dotSize, $dotSize)
$g.FillEllipse($dotBrush, 200 - $dotSize/2, 724 - $dotSize/2, $dotSize, $dotSize)
$g.FillEllipse($dotBrush, 824 - $dotSize/2, 724 - $dotSize/2, $dotSize, $dotSize)

# --- White accent bar under "PC" ---
$barBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(180, 255, 255, 255))
$g.FillRectangle($barBrush, 320, 520, 384, 6)

# --- "PC" text (white on amber) ---
$pcFont = New-Object System.Drawing.Font("Segoe UI Black", 260, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
$pcBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 255, 255))
$pcText = "PC"
$pcSize = $g.MeasureString($pcText, $pcFont)
$pcX = ($size - $pcSize.Width) / 2
$pcY = 180
$g.DrawString($pcText, $pcFont, $pcBrush, $pcX, $pcY)

# --- "PROCELL" text (white on amber) ---
$proFont = New-Object System.Drawing.Font("Segoe UI Semibold", 72, [System.Drawing.FontStyle]::Regular, [System.Drawing.GraphicsUnit]::Pixel)
$proBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 255, 255))
$proText = "PROCELL"
$proSize = $g.MeasureString($proText, $proFont)
$proX = ($size - $proSize.Width) / 2
$proY = 545
$g.DrawString($proText, $proFont, $proBrush, $proX, $proY)

# --- Thin outer border ---
$borderPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(60, 255, 255, 255), 3)
$g.DrawPath($borderPen, $rectPath)

# --- Save ---
$savePath = "C:\Users\pro021\develop\procell_app\tools\icon_1024.png"
$bmp.Save($savePath, [System.Drawing.Imaging.ImageFormat]::Png)
Write-Host "Icon saved to $savePath"

$g.Dispose()
$bmp.Dispose()
$bgBrush.Dispose()
$linePen.Dispose()
$dotBrush.Dispose()
$barBrush.Dispose()
$pcFont.Dispose()
$pcBrush.Dispose()
$proFont.Dispose()
$proBrush.Dispose()
$borderPen.Dispose()
$rectPath.Dispose()
