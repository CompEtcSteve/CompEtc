$validMasks = @(
                "255.255.255.255", "255.255.255.254", "255.255.255.252", "255.255.255.248",
                "255.255.255.240", "255.255.255.224", "255.255.255.192", "255.255.255.128",
                "255.255.255.0", "255.255.254.0", "255.255.252.0", "255.255.248.0",
                "255.255.240.0", "255.255.224.0", "255.255.192.0", "255.255.128.0",
                "255.255.0.0", "255.254.0.0", "255.252.0.0", "255.248.0.0",
                "255.240.0.0", "255.224.0.0", "255.192.0.0", "255.128.0.0",
                "255.0.0.0", "254.0.0.0", "252.0.0.0", "248.0.0.0",
                "240.0.0.0", "224.0.0.0", "192.0.0.0", "128.0.0.0",
                "0.0.0.0"
                )
function Convert-SubnetToDottedDecimal {
    param (
        [int]$CIDR
    )

    # Validate CIDR value
    if ($CIDR -lt 0 -or $CIDR -gt 32) {
        throw "Invalid CIDR value. It must be between 0 and 32. Provided value: $CIDR"
    }

    try {
        # Generate binary mask and convert to dotted decimal
        $binaryMask = ("1" * $CIDR).PadRight(32, "0")
        Write-Host "Binary Mask: $binaryMask" -ForegroundColor Yellow  # Debugging log

        # Split into 8-bit chunks and filter out empty strings
        $octets = $binaryMask -split '(?<=\G.{8})' | Where-Object { $_ -ne '' } | ForEach-Object {
            Write-Host "Processing Octet: $_" -ForegroundColor Cyan  # Debugging log
            [convert]::ToInt32($_, 2)
        }

        return $octets -join "."
    } catch {
        Write-Host "An error occurred while converting CIDR to dotted decimal: $_" -ForegroundColor Red
        throw
    }
}

function Detect-SubnetFormat {
    param (
        [string]$InputData
    )
    try {
        # Check if input is a valid dotted decimal subnet
        if ($InputData -match '^((25[0-5]|2[0-4][0-9]|1?[0-9][0-9])\.){3}(25[0-5]|2[0-4][0-9]|1?[0-9][0-9])$') {
            # Validate subnet mask further by ensuring it's one of the possible valid masks
            )
            if ($validMasks -contains $InputData) {
                Write-Host $InputData
                return $InputData
            } else {
                Write-Host "Invalid dotted decimal subnet mask."
                throw "Invalid dotted decimal subnet mask."
            }
        }

        # Check if input is in CIDR notation and convert it
        elseif ($InputData -match '^\/([0-9]|[12][0-9]|3[0-2])$') {
            $cidrValue = $InputData.TrimStart("/")
            return Convert-SubnetToDottedDecimal -CIDR $cidrValue  # Ensure return statement
        }

        else {
            Write-Host "Invalid subnet format. Please try again."
            $newInput = Read-Host "Enter subnet mask (e.g., 255.255.255.0 or /24)"
            return Detect-SubnetFormat -InputData $newInput  # Recursion for retry
        }
    } catch {
        Write-Host "An error occurred while processing the subnet mask: $_" -ForegroundColor Red
        throw
    }
}

function Configure-NetworkAdapter {
    # Ask the user whether to show all adapters or only active ones
    Write-Host "1: Show all adapters"
    Write-Host "2: Show only active adapters"
    $adapterChoice = Read-Host "Enter your choice (1 or 2)"

    if ($adapterChoice -eq "1") {
        # Show all adapters
        $adapters = Get-NetAdapter
    } elseif ($adapterChoice -eq "2") {
        # Show only active adapters
        $adapters = Get-NetAdapter | Where-Object {$_.Status -eq "Up"}
    } else {
        Write-Host "Invalid choice! Exiting..." -ForegroundColor Red
        return
    }

    if ($adapters.Count -eq 0) {
        Write-Host "No network adapters found based on your selection!" -ForegroundColor Red
        return
    }

    # Display adapters and let the user choose
    Write-Host "Available Network Adapters:"
    $adapters | ForEach-Object {Write-Host "$($_.ifIndex): $($_.Name)"}
    $adapterIndex = Read-Host "Enter the index of the adapter you want to configure"
    $adapter = $adapters | Where-Object { $_.ifIndex -eq $adapterIndex }

    if (-not $adapter) {
        Write-Host "Invalid adapter selection!" -ForegroundColor Red
        return
    }

    Write-Host "You selected: $($adapter.Name)" -ForegroundColor Green

    # Ask user to choose DHCP, Static IP, Multi-Homing, or Change Only DNS
    Write-Host "1: Use DHCP"
    Write-Host "2: Use Static IP"
    Write-Host "3: Configure Multi-Homing"
    Write-Host "4: Change Only DNS"
    $choice = Read-Host "Enter your choice (1, 2, 3, or 4)"

    if ($choice -eq "1") {
        # Configure DHCP using netsh
        Write-Host "Configuring DHCP for $($adapter.Name)..."
        Set-NetIPInterface -InterfaceIndex $($adapter.ifIndex) -Dhcp Enabled
        Set-DnsClientServerAddress -InterfaceIndex $($adapter.ifIndex) -ResetServerAddresses
        Remove-NetRoute -InterfaceIndex $($adapter.ifIndex) -DestinationPrefix "0.0.0.0/0" -Confirm:$false
        Write-Host "DHCP has been configured." -ForegroundColor Green
    } elseif ($choice -eq "2") {
        # Configure Static IP using netsh
        $ipAddress = Read-Host "Enter the static IP address (e.g., 192.168.1.100)"
        $subnetMask = Read-Host "Enter the subnet mask (e.g., 255.255.255.0 or /24)"
        $subnetMask = Detect-SubnetFormat -InputData $subnetMask  # Ensure correct format
        $gateway = Read-Host "Enter the gateway address (e.g., 192.168.1.1) or leave blank"
        $dns1 = Read-Host "Enter the primary DNS server address (e.g., 8.8.8.8) or leave blank"
        if ($dns1) {
            $dns2 = Read-Host "Enter the secondary DNS server address (or leave blank if none)"
        }

        Write-Host "Configuring static IP for $($adapter.Name)..."
        Set-NetIPInterface -InterfaceIndex $($adapter.ifIndex) -Dhcp Disabled
        # Using netsh since it will work on offline adapters
        netsh interface ip set address name="$($adapter.Name)" static $ipAddress $subnetMask $gateway
        # Set DNS servers
        if ($dns1) {
            netsh interface ip set dns name="$($adapter.Name)" static $dns1 primary
            if ($dns2) {
                netsh interface ip add dns name="$($adapter.Name)" $dns2 index=2
            }
        }
        Write-Host "Static IP configuration has been applied." -ForegroundColor Green
    } elseif ($choice -eq "3") {
        # Configure Multi-Homing using netsh
        $primaryIP = Read-Host "Enter the primary IP address"
        $primarySubnet = Read-Host "Enter the subnet mask for the primary IP"

        Write-Host "Configuring primary IP for $($adapter.Name)..."
        Set-NetIPInterface -InterfaceIndex $($adapter.ifIndex) -Dhcp Disabled
        netsh interface ip set address name="$($adapter.Name)" static $primaryIP $primarySubnet
        Write-Host "Primary IP has been configured." -ForegroundColor Green

        # Loop to add additional IPs
        while ($true) {
            $additionalIP = Read-Host "Enter an additional IP address (leave blank to stop)"
            if ([string]::IsNullOrWhiteSpace($additionalIP)) {
                Write-Host "No additional IP entered. Exiting multi-homing configuration." -ForegroundColor Yellow
                break
            }
            $additionalSubnet = Read-Host "Enter the subnet mask for the additional IP"

            Write-Host "Configuring additional IP for $($adapter.Name)..."
            netsh interface ip add address name="$($adapter.Name)" addr=$additionalIP mask=$additionalSubnet
            Write-Host "Additional IP ($additionalIP) has been configured." -ForegroundColor Green
        }
    } elseif ($choice -eq "4") {
        # Change only DNS
        $dns1 = Read-Host "Enter the primary DNS server address (e.g., 8.8.8.8)"
        $dns2 = Read-Host "Enter the secondary DNS server address (or leave blank if none)"
        if ($dns1) {
            netsh interface ip set dns name="$($adapter.Name)" static $dns1 primary
            if ($dns2) {
                netsh interface ip add dns name="$($adapter.Name)" $dns2 index=2
                Write-Host "DNS servers have been changed to $dns1 and $dns2 for $($adapter.Name)." -ForegroundColor Green
            } else {
                Write-Host "DNS server has been changed to $dns1 for $($adapter.Name)." -ForegroundColor Green
            }
        } else {
            Write-Host "No DNS server entered. DNS change skipped." -ForegroundColor Yellow
        }
    } else {
        Write-Host "Invalid choice!" -ForegroundColor Red
        return
    }

    Write-Host "Network adapter configuration completed!" -ForegroundColor Cyan
    Start-Sleep -Seconds 10
}

# Run the function
Configure-NetworkAdapter
