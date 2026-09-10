# Script to estimate backup space for Active Directory, SYSVOL, System State, and Total Backup

# Function to convert size from bytes to human-readable format
function Convert-Size {
    param ([int64]$Bytes)
    switch ($Bytes) {
        {$_ -ge 1TB} {"{0:N2} TB" -f ($Bytes / 1TB); break}
        {$_ -ge 1GB} {"{0:N2} GB" -f ($Bytes / 1GB); break}
        {$_ -ge 1MB} {"{0:N2} MB" -f ($Bytes / 1MB); break}
        {$_ -ge 1KB} {"{0:N2} KB" -f ($Bytes / 1KB); break}
        default {"$Bytes Bytes"; break}
    }
}

# Get the size of the Active Directory database (NTDS)
$ntdsFile = "C:\Windows\NTDS\ntds.dit"
if (Test-Path $ntdsFile) {
    $ntdsSize = (Get-Item $ntdsFile).Length
    $ntdsReadable = Convert-Size $ntdsSize
} else {
    $ntdsSize = 0
    $ntdsReadable = "Not Found"
}

# Get the size of the SYSVOL directory
$sysvolDir = "C:\Windows\SYSVOL"
if (Test-Path $sysvolDir) {
    $sysvolSize = (Get-ChildItem -Recurse $sysvolDir | Measure-Object -Property Length -Sum).Sum
    $sysvolReadable = Convert-Size $sysvolSize
} else {
    $sysvolSize = 0
    $sysvolReadable = "Not Found"
}

# Get the System Volume Information size (Shadow Copies, etc.)
$vssInfo = vssadmin list shadowstorage
$vssUsed = ($vssInfo | Select-String "Used Shadow Copy Storage space" | ForEach-Object {$_ -match '\d+(\.\d+)?\s\w+'; $matches[0]})
$vssAllocated = ($vssInfo | Select-String "Allocated Shadow Copy Storage space" | ForEach-Object {$_ -match '\d+(\.\d+)?\s\w+'; $matches[0]})
$vssMax = ($vssInfo | Select-String "Maximum Shadow Copy Storage space" | ForEach-Object {$_ -match '\d+(\.\d+)?\s\w+'; $matches[0]})

# Estimate space for the system partition (e.g., C: drive)
$systemDrive = Get-PSDrive C
$systemSizeUsed = $systemDrive.Used
$systemReadable = Convert-Size $systemSizeUsed

# Calculate the total estimated size for the backup (System State includes all of the above)
$totalSize = $ntdsSize + $sysvolSize + $systemSizeUsed
$totalReadable = Convert-Size $totalSize

# Display the results
Write-Host "Backup Space Estimation Breakdown:"
Write-Host "---------------------------------"
Write-Host "Active Directory Database (NTDS): $ntdsReadable"
Write-Host "SYSVOL Directory: $sysvolReadable"
Write-Host "System Drive (C:): $systemReadable"
Write-Host ""
Write-Host "Shadow Copy Info (From VSS):"
Write-Host "Used Shadow Copy Storage space: $vssUsed"
Write-Host "Allocated Shadow Copy Storage space: $vssAllocated"
Write-Host "Maximum Shadow Copy Storage space: $vssMax"
Write-Host ""
Write-Host "Total Estimated Backup Size: $totalReadable"

# Optionally return the total size for further use
return $totalSize