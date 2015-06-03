# This configuration configures a Basic WordPress Site
# It requires xPhp, xMySql, xWordPress, and xWebAdministration
# Please review the note about the FQDN variable and
# about the URLs, they may need to be updated.

# ********* NOTE ***********
# If you are not targetting the local machine, 
# or this does not resolve to the correct FQDN for the machine
# Update this to the FQDN of the target machine
# **************************

[string] $role = 'WordPress'
$dataRoot = Split-Path $MyInvocation.MyCommand.Path
$phpTemplatePath = join-Path $dataRoot 'phpConfigTemplate.txt'
$WordPressTemplatePath = Join-Path $dataRoot 'WordPressConfigurationTemplate.ps1'
if (-not (Test-Path $WordPressTemplatePath))
{
    $message = "Missing required file $WordPressTemplatePath"
    # This file is in the samples folder of the resource
    throw $message
}
$plainPassword = 'pass@word1'
$WordPressUserName = 'WordPressUser'
$WordPressDatabase = 'WordPress'

# Generate the contents of the WordPress configuration
$wordPressConfig = & $WordPressTemplatePath -WordPressDatabase $WordPressDatabase -WordPressUserName $WordPressUserName -PlainPassword $plainPassword

# ********* NOTE ***********
# PHP and My SQL change their download URLs frequently.  Please verify the URLs.
# the WordPress and VC Redist URL change less frequently, but should still be verified.
# After verifying the download URLs for the products and update them appropriately.
# **************************


# Configuration to configure a Single machine WordPress Site
Configuration WordPress
{
    param(
        [pscredential] $admin,
        [pscredential] $wordPressUser,
        [pscredential] $credential,
        [string] $fqdn,
        [switch] $skipWordpress

    )
    # Import composite resources
    Import-DscResource -module xMySql 
    Import-DscResource -module xPhp
    Import-DscResource -module xWordPress

    Node $AllNodes.NodeName
    {
        # Make sure we have a folder for the packages
        File PackagesFolder
        {
            DestinationPath = $ExecutionContext.InvokeCommand.ExpandString($Node.PackageFolder)
            Type = 'Directory'
            Ensure = 'Present'
        }

        # Make sure PHP is installed in IIS
        xPhpProvision  php
        {
            InstallMySqlExt = $true
            PackageFolder =  $ExecutionContext.InvokeCommand.ExpandString($Node.PackageFolder)
            DownloadUri = $ExecutionContext.InvokeCommand.ExpandString($Node.Php.DownloadURI)
            DestinationPath = $ExecutionContext.InvokeCommand.ExpandString($Node.Php.Path)
            ConfigurationPath = $ExecutionContext.InvokeCommand.ExpandString($Node.Php.TemplatePath)
            Vc2012RedistDownloadUri = $ExecutionContext.InvokeCommand.ExpandString($Node.Php.Vc2012RedistUri)
            DependsOn = '[File]PackagesFolder'
        }


        # Make sure MySql is installed with a WordPress database
        xMySqlProvision mySql
        {
            ServiceName = 'MySqlService'
            DownloadURI = $ExecutionContext.InvokeCommand.ExpandString($Node.MySqlDownloadURI)
            RootCredential = $credential
            DatabaseName = 'WordPress'
            UserCredential =  $wordPressUser
            DependsOn = '[xPhpProvision]php'
        }
        
        if(!$skipWordpress)
        {
            # Make sure the IIS site for WordPress is created
            # Note, you still need to create the actuall WordPress Site after this.
            xIisWordPressSite iisWordPressSite
            {
                DestinationPath = $ExecutionContext.InvokeCommand.ExpandString($Node.WordPress.Path)
                DownloadUri = $ExecutionContext.InvokeCommand.ExpandString($Node.WordPress.DownloadURI)
                PackageFolder = $ExecutionContext.InvokeCommand.ExpandString($Node.PackageFolder)
                Configuration = $WordPressConfig
                DependsOn = '[xMySqlProvision]mySql'
            }

        
            # Make sure the WordPress site is present
            xWordPressSite WordPressSite
            {
                Uri = $ExecutionContext.InvokeCommand.ExpandString($Node.WordPress.Uri)
                Title = $Node.WordPress.Title
                AdministratorCredential = $Admin
                AdministratorEmail = $Node.WordPress.Email
                DependsOn = '[xIisWordPressSite]iisWordPressSite'
            }
        } 

        # Make sure LCM will reboot if needed
        LocalConfigurationManager
        {
            RebootNodeIfNeeded = $true
            # uncomment when debugging on WMF 5 and above.
            # DebugMode = $true
        }
    }
}


