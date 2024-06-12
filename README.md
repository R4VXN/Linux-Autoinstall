# Linux-Autoinstall
In this repositor there are powershell scripts that create a Linux VM under linux with the Vmware PowerCLI and create a dynamic kickstarter file and host it on a web server

# Requierments

- Powershell for Linux
- On curent Host httpd and php installed
- Custom Redhat 9 ISO with custim isolinux.cfg

# How to Use

 ```bash
 pwsh
  ```

 ```powershell
 vi New-Redhat.ps1
  ```

Change the following Variables to our own:

    $VMHost = "vSphereHost" 
    $ISOPath = "[datastore1] isos/redhat9-4.iso"  
    $NetworkName = "VM Network" 
    $Gateway = "192.168.1.1" 
    $DNS1 = 10.10.10.5
    $DNS2 = 10.10.10.4
    $domain = domain.com
    $Timezone = Europe/Berlin

Save the editet .ps1


Run the Skript

 ```powershell
 ./New-Redhat.ps1
  ```
