@{  
    AllNodes = @(        
        @{
            Role = 'wordpress'
            NodeName = 'localhost'
            PSDscAllowPlainTextPassword = $true;

            WordPress = @{
                Title = 'DSC WordPress Site Title'
                Email = 'dscadmin@contoso.com'
                Uri = 'http://$fqdn'
                DownloadURI = 'http://WordPress.org/latest.zip'
                Path = '$env:SystemDrive\wwwWordPress'
                SiteName = 'WordPress'
                UserName = 'WordPressUser'
                Database = 'WordPress'
            }    
            
            Php = @{
                # Update with the latest "VC11 x64 Non Thread Safe" from http://windows.php.net/download/
                DownloadURI = 'http://windows.php.net/downloads/releases/php-5.6.8-nts-Win32-VC11-x64.zip'
                TemplatePath = '$dataRoot\phpConfigTemplate.txt'
                Path = '$env:SystemDrive\php'
                Vc2012RedistUri = 'http://download.microsoft.com/download/1/6/B/16B06F60-3B20-4FF2-B699-5E9B7962F9AE/VSU_4/vcredist_x64.exe'
            }

            PackageFolder = '$env:SystemDrive\packages'
            MySqlDownloadURI = 'http://dev.mysql.com/get/Downloads/MySQLInstaller/mysql-installer-community-5.6.17.0.msi'
            
         }
    )  
}
