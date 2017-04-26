param([string]$dest, [string]$path, [string]$backup, [string]$logpartial)

#$path = "C:\Files\LtarBoydNorth\"
#$backup = "C:\Files\backups\LtarBoydNorth"
#$dest = "https://ltarcafdatastream.blob.core.windows.net/boydnorth-ectower/raw"

# Program expects a file containing the Azure Access Key to the blob storage account.  Put the key in quotes. 
$key = Get-Content .\blob-key.private

$log = "$logpartial-$(Get-Date -f yyyyMMdd-HHmm).txt"

$numtries = 5
$itr = 0

#Start-Transcript $log -Append -Force
"# Date: $(Get-Date -f yyyyMMdd-HHmm)" >> $log
"# File: $PSCommandPath" >> $log
"# Param(dest): $dest" >> $log
"# Param(path): $path" >> $log
"# Param(backup): $backup" >> $log
"# Param(logpartial): $logpartial" >> $log


"$([Environment]::NewLine)# Copying files to blob storage..." >> $log
Do {
    & "C:\Program Files (x86)\Microsoft SDKs\Azure\AzCopy\AzCopy.exe" /Source:$path /Dest:$dest /DestKey:$key /S /Y /XO /XN *>> $log
    $azcopyresult = $LASTEXITCODE 
    $itr++
} While (($azcopyresult -ne 0) -And ($itr -lt $numtries))

if($itr -ge $numtries)
{
    "$([Environment]::NewLine)# Could not copy files to Azure Blob storage, aborting..." >> $log
}

#------------
"$([Environment]::NewLine)# Moving files to backup..." >> $log
if($LASTEXITCODE -eq 0)
    {
    $files = Get-ChildItem -Path $path -Recurse
    $files | Move-Item -Destination $backup -Verbose -Force *>> $log

    "$([Environment]::NewLine)# Checking success..." >> $log
    foreach($file in $files)
    {
        $filename = [System.IO.Path]::GetFileName($file)
        $oldpath = [System.IO.Path]::Combine($path,$filename)
        $newpath = [System.IO.Path]::Combine($backup, $filename)

        if(![System.IO.File]::Exists($oldpath) -And [System.IO.File]::Exists($newpath))
        {
            "Successfully moved: $oldpath to $newpath" >> $log
        }
        else
        {
            "Failed to move $oldpath to $newpath" >> $log
        }
    }
}
#--------

#Get-ChildItem -Path $path -Recurse | Move-Item -Destination $backup -Verbose -WhatIf -Force *>> $log

#$copied
##if($LASTEXITCODE -eq 0) {
#    $copied = Copy-Item $path\*.* $backup -Recurse -Force -Verbose | Tee $log
#    #$copied
##}
#
#$removed
#foreach($file in $copied)
#{
#    $filename = [System.IO.Path]::GetFileName($file)
#    Remove-Item $path\$filename -WhatIf *>> $log
#}

#Stop-Transcript