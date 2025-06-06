Add-Type -AssemblyName System.Windows.Forms

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
        # Debugging log can be removed in GUI
        $octets = $binaryMask -split '(?<=\G.{8})' | Where-Object { $_ -ne '' } | ForEach-Object {
            [convert]::ToInt32($_, 2)
        }
        return $octets -join "."
    } catch {
        [System.Windows.Forms.MessageBox]::Show("An error occurred while converting CIDR to dotted decimal: $_", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        throw
    }
}

function Detect-SubnetFormat {
    param (
        [string]$InputData
    )
    # Check if input is a valid dotted decimal subnet
    if ($InputData -match '^((25[0-5]|2[0-4][0-9]|1?[0-9][0-9])\.){3}(25[0-5]|2[0-4][0-9]|1?[0-9][0-9])$') {
        return $InputData  # Correctly formatted dotted decimal
    }
    # Check if input is in CIDR notation and convert it
    elseif ($InputData -match '^\/([0-9]|[12][0-9]|3[0-2])$') {
        $cidrValue = $InputData.TrimStart("/")
        return Convert-SubnetToDottedDecimal -CIDR $cidrValue  # Ensure return statement
    }
    else {
        return ""
    }
}

function Configure-NetworkAdapter-GUI {
    # Create Form
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "Network Adapter Configuration"
    $form.Size = New-Object System.Drawing.Size(450, 600)
    $form.StartPosition = "CenterScreen"

    # Adapter list label
    $labelAdapters = New-Object System.Windows.Forms.Label
    $labelAdapters.Text = "Select Network Adapter:"
    $labelAdapters.Location = New-Object System.Drawing.Point(10,20)
    $labelAdapters.AutoSize = $true
    $form.Controls.Add($labelAdapters)

    # ComboBox for adapters
    $comboAdapters = New-Object System.Windows.Forms.ComboBox
    $comboAdapters.Location = New-Object System.Drawing.Point(180, 18)
    $comboAdapters.DropDownStyle = "DropDownList"
    $comboAdapters.Width = 220

    $adapters = Get-NetAdapter | Sort-Object ifIndex
    foreach ($adapter in $adapters) {
        $comboAdapters.Items.Add("$($adapter.ifIndex) : $($adapter.Name)")
    }
    if ($comboAdapters.Items.Count -gt 0) { $comboAdapters.SelectedIndex = 0 }
    $form.Controls.Add($comboAdapters)

    # Configuration type
    $labelType = New-Object System.Windows.Forms.Label
    $labelType.Text = "Configuration Type:"
    $labelType.Location = New-Object System.Drawing.Point(10, 60)
    $labelType.AutoSize = $true
    $form.Controls.Add($labelType)

    $comboType = New-Object System.Windows.Forms.ComboBox
    $comboType.Location = New-Object System.Drawing.Point(180, 58)
    $comboType.Width = 220
    $comboType.Items.AddRange(@("DHCP", "Static IP", "Multi-Homing", "Change Only DNS"))
    $comboType.SelectedIndex = 0
    $form.Controls.Add($comboType)

    # --- Static IP controls ---
    $labelIP = New-Object System.Windows.Forms.Label
    $labelIP.Text = "Static IP Address:"
    $labelIP.Location = New-Object System.Drawing.Point(10, 100)
    $labelIP.AutoSize = $true
    $form.Controls.Add($labelIP)

    $textIP = New-Object System.Windows.Forms.TextBox
    $textIP.Location = New-Object System.Drawing.Point(180, 98)
    $textIP.Width = 220
    $form.Controls.Add($textIP)

    $labelSubnet = New-Object System.Windows.Forms.Label
    $labelSubnet.Text = "Subnet Mask (e.g., 255.255.255.0 or /24):"
    $labelSubnet.Location = New-Object System.Drawing.Point(10, 130)
    $labelSubnet.AutoSize = $true
    $form.Controls.Add($labelSubnet)

    $textSubnet = New-Object System.Windows.Forms.TextBox
    $textSubnet.Location = New-Object System.Drawing.Point(250, 128)
    $textSubnet.Width = 150
    $form.Controls.Add($textSubnet)

    $labelGateway = New-Object System.Windows.Forms.Label
    $labelGateway.Text = "Gateway Address:"
    $labelGateway.Location = New-Object System.Drawing.Point(10, 160)
    $labelGateway.AutoSize = $true
    $form.Controls.Add($labelGateway)

    $textGateway = New-Object System.Windows.Forms.TextBox
    $textGateway.Location = New-Object System.Drawing.Point(180, 158)
    $textGateway.Width = 220
    $form.Controls.Add($textGateway)

    # --- Multi-Homing controls (primary only, additional via popup) ---
    $labelPrimaryIP = New-Object System.Windows.Forms.Label
    $labelPrimaryIP.Text = "Primary IP Address:"
    $labelPrimaryIP.Location = New-Object System.Drawing.Point(10, 190)
    $labelPrimaryIP.AutoSize = $true
    $form.Controls.Add($labelPrimaryIP)

    $textPrimaryIP = New-Object System.Windows.Forms.TextBox
    $textPrimaryIP.Location = New-Object System.Drawing.Point(180, 188)
    $textPrimaryIP.Width = 220
    $form.Controls.Add($textPrimaryIP)

    $labelPrimarySubnet = New-Object System.Windows.Forms.Label
    $labelPrimarySubnet.Text = "Primary Subnet Mask:"
    $labelPrimarySubnet.Location = New-Object System.Drawing.Point(10, 220)
    $labelPrimarySubnet.AutoSize = $true
    $form.Controls.Add($labelPrimarySubnet)

    $textPrimarySubnet = New-Object System.Windows.Forms.TextBox
    $textPrimarySubnet.Location = New-Object System.Drawing.Point(180, 218)
    $textPrimarySubnet.Width = 220
    $form.Controls.Add($textPrimarySubnet)

    # --- DNS controls (shared for all modes where DNS is set) ---
    $labelDNS1 = New-Object System.Windows.Forms.Label
    $labelDNS1.Text = "Primary DNS Server:"
    $labelDNS1.Location = New-Object System.Drawing.Point(10, 250)
    $labelDNS1.AutoSize = $true
    $form.Controls.Add($labelDNS1)

    $textDNS1 = New-Object System.Windows.Forms.TextBox
    $textDNS1.Location = New-Object System.Drawing.Point(180, 248)
    $textDNS1.Width = 220
    $form.Controls.Add($textDNS1)

    $labelDNS2 = New-Object System.Windows.Forms.Label
    $labelDNS2.Text = "Secondary DNS Server (optional):"
    $labelDNS2.Location = New-Object System.Drawing.Point(10, 280)
    $labelDNS2.AutoSize = $true
    $form.Controls.Add($labelDNS2)

    $textDNS2 = New-Object System.Windows.Forms.TextBox
    $textDNS2.Location = New-Object System.Drawing.Point(250, 278)
    $textDNS2.Width = 150
    $form.Controls.Add($textDNS2)

    # --- Hide/Show fields based on selection ---
    $updateFields = {
        $ipFields = $comboType.SelectedItem -eq "Static IP"
        $multiFields = $comboType.SelectedItem -eq "Multi-Homing"
        $dnsFields = ($comboType.SelectedItem -eq "Static IP" -or $comboType.SelectedItem -eq "Change Only DNS")

        $labelIP.Visible = $ipFields
        $textIP.Visible = $ipFields
        $labelSubnet.Visible = $ipFields
        $textSubnet.Visible = $ipFields
        $labelGateway.Visible = $ipFields
        $textGateway.Visible = $ipFields

        $labelPrimaryIP.Visible = $multiFields
        $textPrimaryIP.Visible = $multiFields
        $labelPrimarySubnet.Visible = $multiFields
        $textPrimarySubnet.Visible = $multiFields

        $labelDNS1.Visible = $dnsFields
        $textDNS1.Visible = $dnsFields
        $labelDNS2.Visible = $dnsFields
        $textDNS2.Visible = $dnsFields
    }
    $comboType.add_SelectedIndexChanged($updateFields)
    &$updateFields

    # --- Button to execute ---
    $button = New-Object System.Windows.Forms.Button
    $button.Text = "Apply Configuration"
    $button.Location = New-Object System.Drawing.Point(150, 350)
    $button.Width = 150
    $form.Controls.Add($button)

    # --- Button handler ---
    $button.Add_Click({
        # Adapter selection
        if ($comboAdapters.SelectedItem) {
            $adapterIndex = [int]($comboAdapters.SelectedItem -split ":")[0].Trim()
            $adapter = $adapters | Where-Object { $_.ifIndex -eq $adapterIndex }
        } else {
            [System.Windows.Forms.MessageBox]::Show("No adapter selected.","Error")
            return
        }
        $adapterName = $adapter.Name

        # Which configuration
        $configType = $comboType.SelectedItem

        if ($configType -eq "DHCP") {
            Set-NetIPInterface -InterfaceIndex $adapter.ifIndex -Dhcp Enabled
            Set-DnsClientServerAddress -InterfaceIndex $adapter.ifIndex -ResetServerAddresses
            Remove-NetRoute -InterfaceIndex $adapter.ifIndex -DestinationPrefix "0.0.0.0/0"
            [System.Windows.Forms.MessageBox]::Show("DHCP has been configured for $adapterName.","Success")
        }
        elseif ($configType -eq "Static IP") {
            $ip = $textIP.Text
            $subnet = Detect-SubnetFormat -InputData $textSubnet.Text
            if (-not $subnet) {
                [System.Windows.Forms.MessageBox]::Show("Invalid subnet mask format.","Error")
                return
            }
            $gateway = $textGateway.Text
            $dns1 = $textDNS1.Text
            $dns2 = $textDNS2.Text

            Set-NetIPInterface -InterfaceIndex $adapter.ifIndex -Dhcp Disabled
            netsh interface ip set address name="$adapterName" static $ip $subnet $gateway
            if ($dns1) {
                netsh interface ip set dns name="$adapterName" static $dns1 primary
                if ($dns2) {
                    netsh interface ip add dns name="$adapterName" $dns2 index=2
                }
            }
            [System.Windows.Forms.MessageBox]::Show("Static IP configuration has been applied for $adapterName.","Success")
        }
        elseif ($configType -eq "Multi-Homing") {
            $primaryIP = $textPrimaryIP.Text
            $primarySubnet = $textPrimarySubnet.Text
            if (-not $primaryIP) {
                [System.Windows.Forms.MessageBox]::Show("Primary IP is required for Multi-Homing.","Error")
                return
            }
            Set-NetIPInterface -InterfaceIndex $adapter.ifIndex -Dhcp Disabled
            netsh interface ip set address name="$adapterName" static $primaryIP $primarySubnet
            [System.Windows.Forms.MessageBox]::Show("Primary IP configured. For additional IPs, use command line or extend this GUI.","Info")
        }
        elseif ($configType -eq "Change Only DNS") {
            $dns1 = $textDNS1.Text
            $dns2 = $textDNS2.Text
            if ($dns1) {
                netsh interface ip set dns name="$adapterName" static $dns1 primary
                if ($dns2) {
                    netsh interface ip add dns name="$adapterName" $dns2 index=2
                    [System.Windows.Forms.MessageBox]::Show("DNS servers have been changed to $dns1 and $dns2 for $adapterName.","Success")
                } else {
                    [System.Windows.Forms.MessageBox]::Show("DNS server has been changed to $dns1 for $adapterName.","Success")
                }
            } else {
                [System.Windows.Forms.MessageBox]::Show("No DNS server entered. DNS change skipped.","Warning")
            }
        }
    })

    # Show the form
    $form.Topmost = $true
    [void]$form.ShowDialog()
}

# Run the GUI function
Configure-NetworkAdapter-GUI