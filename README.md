
# Linux Autoinstall with VMware PowerCLI

This repository contains PowerShell scripts designed to automate the creation of a Linux virtual machine (VM) using VMware PowerCLI. It also includes functionality to dynamically generate a kickstart configuration file and host it on a web server.

## Requirements

- PowerShell for Linux: Ensure you have PowerShell installed on your Linux system to run the provided scripts.
- Web Server with PHP: An HTTP server (e.g., Apache) with PHP support installed on the host machine to serve the kickstart file.
- Custom Red Hat Enterprise Linux (RHEL) 9 ISO: A modified ISO image of RHEL 9 with a custom `isolinux.cfg` file is required for the installation process.

## How to Use

1. **Open PowerShell**:
   Start a PowerShell session by entering the following command in your terminal:

   ```bash
   pwsh
   ```

2. **Edit the PowerShell Script**:
   Open the PowerShell script `New-Redhat.ps1` for editing:

   ```powershell
   vi New-Redhat.ps1
   ```

   Update the script by changing the following variables to match your setup:

   ```powershell
   $VMHost = "example-host"
   $ISOPath = "[datastore1] ISO/Linux/example.iso"
   $NetworkName = "example-network"
   $Gateway = "192.168.1.1"
   DNS1 Adress= 10.10.10.5
   DNS2 Adress = 10.10.10.4
   domain = "domain.com"
   Timezone = "Europe/Berlin"
   ```

   Save your changes to the script.

3. **Run the Script**:
   Execute the script to create and configure the VM:

   ```powershell
   ./New-Redhat.ps1
   ```
