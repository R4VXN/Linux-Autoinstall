Function New-LinuxVM {
    # Statische Konfigurationswerte
    $VMHost = "vSphereHost"  # Ändere diesen Wert in den Namen des VMware Hosts
    $ISOPath = "[datastore1] isos/redhat9-4.iso"  # Pfad zur ISO-Datei im VMware Datastore
    $NetworkName = "VM Network"  # Netzwerkname in VMware
    $Gateway = "192.168.1.1"  # Standard-Gateway
    $DNS1 = 10.10.10.5
    $DNS2 = 10.10.10.4
    $domain = domain.com
    $Timezone = Europe/Berlin

    # Benutzereingaben einholen
    $Name = Read-Host "Bitte geben Sie den Namen der VM ein"
    $Datastore = Read-Host "Bitte geben Sie den Datastore-Namen ein"
    $DiskGB = Read-Host "Bitte geben Sie die Größe der Festplatte in GB ein"
    $MemoryGB = Read-Host "Bitte geben Sie den Arbeitsspeicher in GB ein"
    $NumCpu = Read-Host "Bitte geben Sie die Anzahl der CPUs ein"
    $Notes = Read-Host "Bitte geben Sie Notizen zur VM ein"
    $GuestID = Read-Host "Bitte geben Sie die Guest ID ein"
    $IP = Read-Host "Bitte geben Sie die IP-Adresse ein"

    # VM erstellen
    $VM = New-VM -VMHost $VMHost -Name $Name -Datastore $Datastore -DiskGB $DiskGB -DiskStorageFormat Thick -MemoryGB $MemoryGB -NumCpu $NumCpu -NetworkName $NetworkName -Notes $Notes -GuestID $GuestID

    # Überprüfen und VM stoppen, wenn nötig, um das CD-Laufwerk sicher hinzuzufügen
    if ((Get-VM -Name $Name).PowerState -eq "PoweredOn") {
        Stop-VM -VM $VM -Confirm:$false -Kill
        Start-Sleep -Seconds 10  # Kurze Pause, um sicherzustellen, dass die VM gestoppt ist
    }

    # Überprüfen, ob die VM ein CD-Laufwerk hat und ein neues hinzufügen
    $CDrive = Get-CDDrive -VM $VM
    if (-not $CDrive) {
        $CDrive = New-CDDrive -VM $VM -Confirm:$false
    }

    # VM starten
    Start-VM -VM $VM -Confirm:$false
    Start-Sleep -Seconds 10  # Warten, bis die VM vollständig hochgefahren ist

    # Konfigurieren Sie das CD-Laufwerk mit der ISO-Datei, nachdem die VM gestartet wurde
    Set-CDDrive -CD $CDrive -IsoPath $ISOPath -StartConnected $true -Connected $true -Confirm:$false


    # Kickstart-Konfigurationsdatei erstellen
    $kickstartContent = @"
# Kickstart configuration for $Name
lang en_US
keyboard --xlayouts='de'
timezone $Timezone --isUtc
rootpw --iscrypted yourrootsecret
reboot
text
cdrom
bootloader --append="rhgb quiet crashkernel=1G-4G:192M,4G-64G:256M,64G-:512M"
zerombr
clearpart --all --initlabel
autopart
network --bootproto=static --ip=$IP --netmask=255.255.255.0 --gateway=$Gateway --nameserver=$DNS1,$DNS2 --hostname=$Name --noipv6 --search=$domain
firstboot --disable
selinux --enforcing
firewall --enabled
%packages
@^minimal-environment
%post
# Install Node Exporter
mkdir /opt/node_exporter
cd /opt/node_exporter
curl -LO https://github.com/prometheus/node_exporter/releases/download/v*/node_exporter-*-linux-amd64.tar.gz
tar xvfz node_exporter-*-linux-amd64.tar.gz --strip-components=1
./node_exporter --web.listen-address=":9100" &
echo '[Unit]
Description=Node Exporter

[Service]
ExecStart=/opt/node_exporter/node_exporter

[Install]
WantedBy=default.target' > /etc/systemd/system/node_exporter.service
systemctl enable node_exporter
systemctl start node_exporter
%end
"@

    $kickstartFilePath = "/var/www/html/RHks.php"
    $kickstartContent | Out-File -FilePath $kickstartFilePath -Encoding ASCII -Force

 # VM ausschalten
 Stop-VM -VM $VM -Confirm:$false -Kill
 Start-Sleep -Seconds 20  # Kurze Pause, um sicherzustellen, dass die VM komplett ausgeschaltet ist

 # VM erneut starten
 Start-VM -VM $VM -Confirm:$false
 Start-Sleep -Seconds 20  # Warten, um sicherzustellen, dass die VM vollständig hochgefahren ist

 Write-Host "VM '$Name' wurde erfolgreich erstellt und konfiguriert. Kickstart-Datei wurde unter $kickstartFilePath gespeichert."
}

# Diese Funktion aufrufen, um die VM zu erstellen
New-LinuxVM
