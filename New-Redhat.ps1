Function New-LinuxVM {
    # Connect to the vCenter Server
    $vCenterServer = "example-vcs-server"
    $vCenterUser = "admin@example.com"
    $vCenterPass = "examplePassword123!"
    $SecurePassword = ConvertTo-SecureString $vCenterPass -AsPlainText -Force
    $Credential = New-Object System.Management.Automation.PSCredential ($vCenterUser, $SecurePassword)
    Connect-VIServer -Server $vCenterServer -Credential $Credential

    # Datastore Selection
    $datastores = @("datastore1", "datastore2", "datastore3", "datastore4")
    $datastoreMenu = $datastores | ForEach-Object { "$($datastores.IndexOf($_) + 1): $_" } | Out-String
    Write-Host "Please select a datastore from the following list:"
    Write-Host $datastoreMenu
    $selectedDatastoreIndex = Read-Host "Enter the number of the desired datastore"
    try {
        $selectedDatastoreIndex = [int]$selectedDatastoreIndex
        $Datastore = $datastores[$selectedDatastoreIndex - 1]
    } catch {
        Write-Host "Invalid selection, script will end."
        return
    }

    # Static Configuration Values
    $VMHost = "example-host"
    $ISOPath = "[datastore1] ISO/Linux/example.iso"  # Correct ISO path
    $NetworkName = "example-network"
    $Gateway = "192.168.1.1"
    $GuestID = "rhel9_64Guest"

    # Collect User Inputs
    $Name = Read-Host "Please enter the VM name"
    $DiskGB = Read-Host "Please enter the disk size in GB"
    $MemoryGB = Read-Host "Please enter the RAM size in GB"
    $NumCpu = Read-Host "Please enter the number of CPUs"
    $Notes = Read-Host "Please enter notes about the VM"
    $IP = Read-Host "Please enter the IP address"

    # Create VM
    $VM = New-VM -VMHost $VMHost -Name $Name -Datastore $Datastore -DiskGB $DiskGB -DiskStorageFormat Thick -MemoryGB $MemoryGB -NumCpu $NumCpu -NetworkName $NetworkName -Notes $Notes -GuestID $GuestID

    # Check and stop VM if necessary to safely add the CD drive
    if ((Get-VM -Name $Name).PowerState -eq "PoweredOn") {
        Stop-VM -VM $VM -Confirm:$false -Kill
        Start-Sleep -Seconds 10  # Short pause to ensure the VM is stopped
    }

    # Check if the VM has a CD drive and add a new one if not
    $CDrive = Get-CDDrive -VM $VM
    if (-not $CDrive) {
        $CDrive = New-CDDrive -VM $VM -Confirm:$false
    }

    # Start the VM
    Start-VM -VM $VM -Confirm:$false
    Start-Sleep -Seconds 10  # Wait until the VM is fully booted

    # Configure the CD drive with the ISO file after the VM has started
    Set-CDDrive -CD $CDrive -IsoPath $ISOPath -StartConnected $true -Connected $true -Confirm:$false

    # Generate and save the kickstart file
    $kickstartContent = @"
#version=RHEL9
install
cdrom
lang en_US
keyboard --xlayouts='us'
timezone Europe/Berlin --isUtc
rootpw --iscrypted $(echo yourPassword | openssl passwd -1 -stdin)
reboot
text
bootloader --append="rhgb quiet crashkernel=1G-4G:192M, 4G-64G:256M, 64G-:512M"
zerombr
clearpart --all --initlabel
autopart
network --bootproto=static --ip=$IP --netmask=255.255.255.0 --gateway=$Gateway --nameserver=192.168.1.2,192.168.1.3 --hostname=$Name --domain=example.com
firstboot --disable
selinux --enforcing
firewall --enabled
%packages
@^minimal-environment
%end
"@

    $kickstartFilePath = "/var/www/html/kickstart.php"
    $kickstartContent | Out-File -FilePath $kickstartFilePath -Encoding ASCII -Force

    # Shut down the VM
    Stop-VM -VM $VM -Confirm:$false -Kill
    Start-Sleep -Seconds 20  # Short pause to ensure the VM is completely shut down

    # Restart the VM
    Start-VM -VM $VM -Confirm:$false
    Start-Sleep -Seconds 20  # Wait to ensure the VM is fully booted

    Write-Host "VM '$Name' has been successfully created and configured. Kickstart file saved at $kickstartFilePath."
}

# Call this function to create the VM
New-LinuxVM
