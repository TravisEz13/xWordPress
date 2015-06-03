# Setup Demo 
import-module .\Samples\Azure\AzureProvision.psm1 -Force 
# List the resources
Get-ChildItem .\DscResources

# Let's start with the composite resource
# It is composed of the a folder, 2 WebSites, 
# a remote file, an archive, and a file
powershell_ise.exe   .\DscResources\xIisWordPressSite\xIisWordPressSite.Schema.psm1

# Let's move on to an example of how to use the 
# Composite resource.
powershell_ise.exe  .\samples\wordpressdemoAzureDscExt.psm1

# Get the existing VM for the demo
$vm = Get-AzureDemoVm 

# Open the web site
Start-Process "$($vm.DNSName)"

# Update the vm with the DSC Configuration
Update-AzureDemoWordpressVm -vm $vm -password 'Pa$$word'

# Get the status of the configuration on the VM
Get-AzureVMDscExtensionStatus -VM $vm

# Open the web site
Start-Process "$($vm.DNSName)"