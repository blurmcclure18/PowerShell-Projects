$Credential = Get-Credential "DOMAIN\ADMIN ACCOUNT"

[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic') | Out-Null 

function join-domain {
    $name = [Microsoft.VisualBasic.Interaction]::InputBox("Enter Desired Computer Name ")

    $ComputerName = "$name"

    $Domain = "DOMAIN.NAME.LAB"
    $Server = "DOMAIN CONTROLLER"
    Add-Computer -DomainName $Domain -DomainCredential $Credential -Server $Server -OUPath 'OU=COMPUTEROU,DC=DOMAIN,DC=DOMAIN,DC=com' -NewName $ComputerName -Verbose
}

function set-newip {
    $IP = read-host -prompt "Enter Desired IP Address "
    $MaskBits = 24 # This means subnet mask = 255.255.255.0
    $Gateway = read-host -prompt "Enter Default Gateway "
    $Dns = read-host -prompt "Enter DNS Settings "
    
    $IPType = "IPv4"
    
    # Retrieve the network adapter that you want to configure
    $adapter = Get-NetAdapter | ? { $_.Status -eq "up" }
    
    # Remove any existing IP, gateway from our ipv4 adapter
    If (($adapter | Get-NetIPConfiguration).IPv4Address.IPAddress) {
        $adapter | Remove-NetIPAddress -AddressFamily $IPType -Confirm:$false
    }
    If (($adapter | Get-NetIPConfiguration).Ipv4DefaultGateway) {
        $adapter | Remove-NetRoute -AddressFamily $IPType -Confirm:$false
    }
    
    # Configure the IP address and default gateway
    $adapter | New-NetIPAddress `
        -AddressFamily $IPType `
        -IPAddress $IP `
        -PrefixLength $MaskBits `
        -DefaultGateway $Gateway
    
    # Configure the DNS client server IP addresses
    $adapter | Set-DnsClientServerAddress -ServerAddresses $DNS
}

$appdeploy = "C:\AppDeploy"

function get-installers {
    New-PSDrive -Name "T" -Root "\\SERVER\PATH TO\INSTALLERS\FOLDER" -Persist -PSProvider "FileSystem" -Credential $Credential

    & Robocopy.exe "T:\Installers" "C:\AppDeploy" /mt:128 /E
}

function install-firefox {
    Start-Process msiexec.exe -ArgumentList "/I $appdeploy\firefox\firefox.msi /passive" -Wait
}

set-newip

sleep 1

join-domain

sleep 1

get-installers

sleep 2

install-firefox

Remove-Item -Path $appdeploy -Recurse

Read-Host -Prompt "To finish setup a restart is required."

Restart-Computer

#END OF SCRIPT