param($vm, [switch] $publish)
$dataRoot = Split-Path $MyInvocation.MyCommand.Path

$plainPassword = 'pass@word1'
$pwd = convertTo-SecureString -String $plainPassword -AsPlainText -Force
$WordPressUserName = 'WordPressUser'
$WordPressDatabase = 'WordPress'
$Admin = New-Object -TypeName System.Management.Automation.PSCredential -argumentlist ('DscAdmin',$pwd)
$User = New-Object -TypeName System.Management.Automation.PSCredential -argumentlist ($WordPressUserName,$pwd)  
$Credential = New-Object -TypeName System.Management.Automation.PSCredential -argumentlist ('userNameNotUsed',$pwd) #the password for root. no user name is needed as MySql installer is using only the user "root".

$zipName = 'wordPressDemoAzureDscExt.psm1.zip'
if($publish)
{
    Publish-AzureVMDscConfiguration  -ConfigurationPath (Join-Path $dataRoot $zipName ) -Verbose -Force
}
$port = $Global:__vm |Get-AzureEndpoint -Name http
if(!$port)
{
    $vm | Add-AzureEndpoint -LocalPort 80 -PublicPort 80 -Name HTTP -Protocol TCP
}
Set-AzureVMDscExtension -VM $vm -ConfigurationArgument @{
        fqdn=(([uri]$global:__vm.DNSName).Host)
        admin = $Admin
        wordPressUser = $User
        Credential = $Credential
    } -ConfigurationArchive $zipName -ConfigurationName WordPress -ConfigurationDataPath (Join-Path $dataRoot wordpressdemoAzureDscExt.psd1)  -Verbose
$vm | Update-AzureVM -Verbose