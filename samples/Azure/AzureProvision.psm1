Function New-AzureDemoVm
{
[cmdletbinding()]
Param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $AdminUsername,
        [ValidateNotNullOrEmpty()]
        [string]
        $location = 'West US',
        [ValidateNotNullOrEmpty()]
        [string]
        $machineName,
        [Parameter(Mandatory=$true)]
        [string]
        $password
  )

    function New-AzureMachineName
    {
        [string] $username = $env:USERNAME
        $randomChars = 14- $username.Length
        [System.Int64] $min = [System.Math]::Pow(10,$randomChars-1)
        [System.Int64] $Max = [System.Math]::Pow(10,$randomChars)-1
        $result = "$username$(Get-Random -Minimum $min -Maximum $max)"
        return $result
    }  


    if([string]::IsNullOrWhiteSpace($machineName))
    {
      $machineName = New-AzureMachineName
    }

    # Get the 2012 R2 Images
    $images = get-azurevmimage | Where-Object{$_.location -match $location -and $_.label -notmatch 'sql' -and $_.label -notmatch 'RightImage' -and $_.label -match '^windows server 2012 R2'} 
    # Get the latest image date
    $latestImagePublishedDate = $images | Select-Object -Unique publishedDate | Sort-Object -Property publishedDate -Descending  |  Select-Object -First 1
    #get the latest Image
    $image = $images.Where{$_.PublishedDate -eq $latestImagePublishedDate.PublishedDate}

    $vm = New-AzureQuickVM -Windows -Name $machineName -Password $password -AdminUsername $AdminUserName -EnableWinRMHttp -ImageName $image.ImageName -ServiceName $machineName -Location $location
    return $vm
}

Function Update-AzureDemoWordPressVm
{
[cmdletbinding()]
Param(
    [Parameter(Mandatory=$true)]
    [Microsoft.WindowsAzure.Commands.ServiceManagement.Model.PersistentVMRoleListContext]
    $vm,
    [Parameter(Mandatory=$true)]
    [string]
    $password,

    [ValidateSet('Provision','Prepare')]
    $configuration = 'Provision'


    )    


    Write-Verbose -Message 'Creating Zip ....' -Verbose
    if($configuration -ieq 'Provision')
    {
        $zip = &$PSScriptRoot\CreateSingleNodeEndToEndZip.ps1 -xWordPressFolder ((Resolve-Path $PSScriptRoot\..\..).ProviderPath)
        $skip = $true
    }
    else
    {
        $zip = &$PSScriptRoot\CreatePrerequisitesZip.ps1 -xWordPressFolder ((Resolve-Path $PSScriptRoot\..\..).ProviderPath)
        $skip = $false
    }

    $zipName = split-path -Leaf $zip
    Write-Verbose -Message 'Publishing Zip ....' -Verbose
    Publish-AzureVMDscConfiguration -ConfigurationPath $zip -Force  -Verbose

    $securePassword = $password | ConvertTo-SecureString -AsPlainText -Force
    $secureDbUserPassword = 'pass@word1' | ConvertTo-SecureString -AsPlainText -Force
    $administrator = New-Object System.Management.Automation.PSCredential 'administrator',$securePassword
    $user = New-Object System.Management.Automation.PSCredential 'WordPressUser',$secureDbUserPassword

    Write-Verbose -Message 'Setting Extension ....' -Verbose
    $port = $vm |Get-AzureEndpoint -Name http
    if(!$port)
    {
        $vm | Add-AzureEndpoint -LocalPort 80 -PublicPort 80 -Name HTTP -Protocol TCP
    }
    Set-AzureVMDscExtension -VM $vm -ConfigurationArgument @{
            fqdn=(([uri]$vm.DNSName).Host)
            admin = $administrator
            wordPressUser = $user
            Credential = $administrator
        } -ConfigurationArchive $zipName -ConfigurationName WordPress -ConfigurationDataPath "$PSScriptRoot\..\wordpressdemoAzureDscExt.psd1"  -Verbose

    Write-Verbose -Message 'Updating VM ....' -Verbose
    $vm|Update-AzureVM
    Write-Verbose -Message 'Done!' -Verbose
}

function Get-AzureDemoVm
{
    return Get-AzureVm | Where-Object{$_.Name -like 'tplunk*'} | Out-GridView -Title 'Select VM' -OutputMode Single
}