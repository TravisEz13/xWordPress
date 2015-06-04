param(
  [string] $xWordpressFolder
)

# Create Temp folders
$tempFolder = "$env:temp\$([guid]::newguid())"
$zipFolder = "$env:temp\$([guid]::newguid())"
if(!(test-path $tempfolder))
{
  mkdir $tempFolder > $null
}

if(!(test-path $zipfolder))
{
  mkdir $zipFolder > $null
}

function Get-Repo
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory=$true, Position=0)]
        [System.String]
        $resourceToClone
        ,

        $branch = 'master'
    )
    
    git.exe clone --depth 1 --branch $branch "https://github.com/PowerShell/$resourceToClone.git" "$tempFolder\$resourceToClone" 2> $null
    Remove-Item -Recurse -Force "$tempFolder\$resourceToClone\.git"
}

# clone and copy files to temp folders
Get-Repo -resourceToClone 'xPsDesiredStateConfiguration'
Get-Repo -resourceToClone 'xMySql'
Get-Repo -resourceToClone 'xWebAdministration'
Get-Repo -resourceToClone 'xPhp' -branch 'dev'
#copy-item 'C:\Users\tplunk\Desktop\old\wordpressdemo\xWebAdministration' "$tempFolder\xWebAdministration" -recurse

copy-item $xWordpressFolder "$tempFolder\xWordPress" -recurse
Remove-Item -Recurse -Force "$tempFolder\xWordPress\.git"

copy-item "$xWordpressFolder\Samples\wordpressdemoAzureDscExt.psm1" $tempFolder
copy-item "$xWordpressFolder\Samples\WordPressConfigurationTemplate.ps1" $tempFolder
copy-item "$xWordpressFolder\Samples\PhpConfigTemplate.txt" $tempFolder

# Zip Folder
$zipFile = "$zipFolder\wordpressdemoAzureDscExt.psm1.zip"
Add-Type -assemblyname System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::CreateFromDirectory($tempFolder, $zipFile)
Remove-Item -Recurse -Force $tempFolder

# Publish arftifact if in AppVeyor
if((Get-Command -Name Push-AppveyorArtifact -ErrorAction SilentlyContinue))
{
  Push-AppveyorArtifact $zipFile
}
else
{
  Write-Verbose -message "Not running in appveyor, zipfile is at:  $zipfile" -verbose
  Write-Output $zipFile
}
