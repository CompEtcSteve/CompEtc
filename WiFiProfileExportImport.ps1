<#
.SYNOPSIS
    Export or import Wi-Fi profiles on Windows 10/11.

.DESCRIPTION
    This script allows you to export all, specific, or selected Wi-Fi profiles to XML files,
    and import previously exported profiles. You can interactively choose profiles to export or import,
    or choose the operation (Export, Import, or Exit) interactively if no switches are specified.

.PARAMETER Export
    Export Wi-Fi profiles. Use -All to export all profiles, -Profile to specify one,
    or -Select to pick one or more interactively.

.PARAMETER Import
    Import Wi-Fi profiles from XML files in a specified folder. Use -All to import all,
    or -Select to choose interactively.

.PARAMETER All
    When used with -Export or -Import, processes all profiles.

.PARAMETER Profile
    When used with -Export, exports only the specified profile name.

.PARAMETER Select
    When used with -Export or -Import, lets you select profiles interactively.

.PARAMETER Folder
    Path to save exported profiles or read profiles for import.

.EXAMPLE
    .\WiFiProfileExportImport.ps1
    # Prompts for Export, Import, or Exit, and then for further options.

.EXAMPLE
    .\WiFiProfileExportImport.ps1 -Export -All -Folder "C:\WiFiBackups"

.EXAMPLE
    .\WiFiProfileExportImport.ps1 -Export -Profile "HomeWiFi" -Folder "C:\WiFiBackups"

.EXAMPLE
    .\WiFiProfileExportImport.ps1 -Export -Select -Folder "C:\WiFiBackups"

.EXAMPLE
    .\WiFiProfileExportImport.ps1 -Import -All -Folder "C:\WiFiBackups"

.EXAMPLE
    .\WiFiProfileExportImport.ps1 -Import -Select -Folder "C:\WiFiBackups"
#>

param(
    [switch]$Export,
    [switch]$Import,
    [switch]$All,
    [string]$Profile,
    [switch]$Select,
    [string]$Folder = ".\WiFiProfiles"
)

function Get-WiFiProfileNames {
    netsh wlan show profiles | Select-String "All User Profile" | ForEach-Object {
        ($_ -split ':')[1].Trim()
    }
}

function Export-WiFiProfiles {
    param(
        [switch]$All,
        [string]$Profile,
        [switch]$Select,
        [string]$Folder
    )
    if (-not (Test-Path $Folder)) {
        New-Item -ItemType Directory -Path $Folder | Out-Null
    }

    if ($All) {
        $profiles = Get-WiFiProfileNames
    } elseif ($Profile) {
        $profiles = @($Profile)
    } elseif ($Select) {
        $allProfiles = Get-WiFiProfileNames
        if ($allProfiles.Count -eq 0) {
            Write-Host "No Wi-Fi profiles found."
            return
        }
        Write-Host "`nSelect profile(s) to export (comma separated numbers):"
        for ($i = 0; $i -lt $allProfiles.Count; $i++) {
            Write-Host "[$($i+1)] $($allProfiles[$i])"
        }
        $selection = Read-Host "Enter number(s) (e.g. 1,3,5)"
        $indices = $selection -split "," | ForEach-Object { ($_ -as [int]) - 1 }
        $profiles = @()
        foreach ($idx in $indices) {
            if ($idx -ge 0 -and $idx -lt $allProfiles.Count) {
                $profiles += $allProfiles[$idx]
            }
        }
        if (-not $profiles -or $profiles.Count -eq 0) {
            Write-Host "No profiles selected."
            return
        }
    } else {
        Write-Host "Specify -All to export all profiles, -Profile <name>, or -Select for interactive selection."
        return
    }

    foreach ($p in $profiles) {
        Write-Host "Exporting profile: $p"
        netsh wlan export profile "$p" key=clear folder="$Folder" | Out-Null
    }
    Write-Host "Export completed. Files saved to $Folder"
}

function Import-WiFiProfiles {
    param(
        [switch]$All,
        [switch]$Select,
        [string]$Folder
    )
    if (-not (Test-Path $Folder)) {
        Write-Host "Import folder '$Folder' does not exist."
        return
    }
    $xmlFiles = Get-ChildItem -Path $Folder -Filter *.xml
    if ($xmlFiles.Count -eq 0) {
        Write-Host "No Wi-Fi profile XML files found in $Folder."
        return
    }

    if ($All) {
        $filesToImport = $xmlFiles
    } elseif ($Select) {
        Write-Host "`nSelect profile(s) to import (comma separated numbers):"
        for ($i = 0; $i -lt $xmlFiles.Count; $i++) {
            Write-Host "[$($i+1)] $($xmlFiles[$i].Name)"
        }
        $selection = Read-Host "Enter number(s) (e.g. 1,2,4)"
        $indices = $selection -split "," | ForEach-Object { ($_ -as [int]) - 1 }
        $filesToImport = @()
        foreach ($idx in $indices) {
            if ($idx -ge 0 -and $idx -lt $xmlFiles.Count) {
                $filesToImport += $xmlFiles[$idx]
            }
        }
        if (-not $filesToImport -or $filesToImport.Count -eq 0) {
            Write-Host "No profiles selected for import."
            return
        }
    } else {
        Write-Host "Specify -All to import all profiles, or -Select for interactive selection."
        return
    }

    foreach ($file in $filesToImport) {
        Write-Host "Importing profile from: $($file.Name)"
        netsh wlan add profile filename="$($file.FullName)" user=all | Out-Null
    }
    Write-Host "Import completed."
}

function Show-MainMenu {
    Write-Host ""
    Write-Host "Wi-Fi Profile Export/Import Tool"
    Write-Host "================================"
    Write-Host "[1] Export Wi-Fi profiles"
    Write-Host "[2] Import Wi-Fi profiles"
    Write-Host "[3] Exit"
    $choice = Read-Host "Choose an option (1-3)"
    return $choice
}

function Show-ExportMenu {
    Write-Host ""
    Write-Host "Export Options:"
    Write-Host "[1] Export ALL Wi-Fi profiles"
    Write-Host "[2] Export a specific Wi-Fi profile"
    Write-Host "[3] Select profile(s) to export"
    Write-Host "[4] Back"
    $choice = Read-Host "Choose an option (1-4)"
    return $choice
}

function Show-ImportMenu {
    Write-Host ""
    Write-Host "Import Options:"
    Write-Host "[1] Import ALL Wi-Fi profiles"
    Write-Host "[2] Select profile(s) to import"
    Write-Host "[3] Back"
    $choice = Read-Host "Choose an option (1-3)"
    return $choice
}

# If no main operation switch is specified, show menu
if (-not ($Export -or $Import)) {
    while ($true) {
        $mainChoice = Show-MainMenu
        switch ($mainChoice) {
            "1" {
                while ($true) {
                    $exportChoice = Show-ExportMenu
                    switch ($exportChoice) {
                        "1" {
                            Export-WiFiProfiles -All -Folder $Folder
                            continue
                        }
                        "2" {
                            $profiles = Get-WiFiProfileNames
                            if ($profiles.Count -eq 0) {
                                Write-Host "No Wi-Fi profiles found."
                                continue
                            }
                            Write-Host "`nAvailable profiles:"
                            for ($i = 0; $i -lt $profiles.Count; $i++) {
                                Write-Host "[$($i+1)] $($profiles[$i])"
                            }
                            $idx = (Read-Host "Enter number of profile to export") -as [int]
                            if ($idx -and $idx -gt 0 -and $idx -le $profiles.Count) {
                                Export-WiFiProfiles -Profile $profiles[$idx-1] -Folder $Folder
                            } else {
                                Write-Host "Invalid selection."
                            }
                            continue
                        }
                        "3" {
                            Export-WiFiProfiles -Select -Folder $Folder
                            continue
                        }
                        "4" { $mainChoice = Show-MainMenu }
                    }
                }
            }
            "2" {
                while ($true) {
                    $importChoice = Show-ImportMenu
                    switch ($importChoice) {
                        "1" {
                            Import-WiFiProfiles -All -Folder $Folder
                            continue
                        }
                        "2" {
                            Import-WiFiProfiles -Select -Folder $Folder
                            continue
                        }
                        "3" { $mainChoice = Show-MainMenu }
                    }
                }
            }
            "3" { exit }
        }
    }
}
elseif ($Export) {
    Export-WiFiProfiles -All:$All -Profile:$Profile -Select:$Select -Folder:$Folder
}
elseif ($Import) {
    Import-WiFiProfiles -All:$All -Select:$Select -Folder:$Folder
}
else {
    Write-Host "Specify either -Export or -Import. Use -? for help."
}
