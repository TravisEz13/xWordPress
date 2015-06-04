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

    # Create Zip
    Write-Verbose -Message '**************************' -Verbose
    Write-Verbose -Message 'Creating Zip ....' -Verbose
    $zip = New-ConfigurationZip -Configuration $configuration

    $zipName = split-path -Leaf $zip
    # Publish Zip
    Write-Verbose -Message '**************************' -Verbose
    Write-Verbose -Message 'Publishing Zip ....' -Verbose
    Publish-AzureVMDscConfiguration -ConfigurationPath $zip -Force  -Verbose

    # Create Parameters
    $securePassword = $password | ConvertTo-SecureString -AsPlainText -Force
    $secureDbUserPassword = 'pass@word1' | ConvertTo-SecureString -AsPlainText -Force
    $administrator = New-Object System.Management.Automation.PSCredential 'administrator',$securePassword
    $user = New-Object System.Management.Automation.PSCredential 'WordPressUser',$secureDbUserPassword

    Write-Verbose -Message 'Setting Extension ....' -Verbose
    # Open Port
    $port = $vm |Get-AzureEndpoint -Name http
    if(!$port)
    {
        $vm | Add-AzureEndpoint -LocalPort 80 -PublicPort 80 -Name HTTP -Protocol TCP
    }
    # Set Extension
    Set-AzureVMDscExtension -VM $vm -ConfigurationArgument @{
            fqdn=(([uri]$vm.DNSName).Host)
            admin = $administrator
            wordPressUser = $user
            Credential = $administrator
        } -ConfigurationArchive $zipName -ConfigurationName WordPress -ConfigurationDataPath "$PSScriptRoot\..\wordpressdemoAzureDscExt.psd1"  -Verbose

    # Update VM
    Write-Verbose -Message '**************************' -Verbose
    Write-Verbose -Message 'Updating VM ....' -Verbose
    $vm|Update-AzureVM
    Write-Verbose -Message 'Done!' -Verbose
}

function Wait-AzureVmDscExtension
{
[cmdletbinding()]
Param(
    [Parameter(Mandatory=$true)]
    [Microsoft.WindowsAzure.Commands.ServiceManagement.Model.PersistentVMRoleListContext]
    $vm,
    [DateTime] $startingTime = [datetime]::MinValue
    )
    $extensionDoneStatusCodes = @( 1,7,8)
    $status = $null
    while (-not $status -or $status.StatusCode -notin $extensionDoneStatusCodes -or $status.TimeStamp -lt $startingTime )
    { 
        $status = Get-AzureVMDscExtensionStatus -VM $vm
        if($status.StatusCode -notin $extensionDoneStatusCodes -or $status.TimeStamp -lt $startingTime )
        {
            if($status.TimeStamp -lt $startingTime)
            {
                Write-Verbose -Verbose 'Status is stale, Refreshing...'
            }
            else
            {
                Write-Verbose -Verbose "Refreshing Status: $($Status.StatusCode) - $($Status.StatusMessage)"
            }
            Start-Sleep -Seconds 45
        }
    }
    
    return $status
}
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

function Get-AzureDemoVm
{
    return Get-AzureVm | Where-Object{$_.Name -like 'tplunk*'} | Out-GridView -Title 'Select VM' -OutputMode Single
}

function New-ConfigurationZip
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory=$true, Position=0, HelpMessage='Please add a help message here')]
        [Object]
        $Configuration
    )
    
    
    if($configuration -ieq 'Provision')
    {
        $zip = &$PSScriptRoot\CreateSingleNodeEndToEndZip.ps1 -xWordPressFolder ((Resolve-Path $PSScriptRoot\..\..).ProviderPath)
    }
    else
    {
        $zip = &$PSScriptRoot\CreatePrerequisitesZip.ps1 -xWordPressFolder ((Resolve-Path $PSScriptRoot\..\..).ProviderPath)
    }
    return $zip
}
