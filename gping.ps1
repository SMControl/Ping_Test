# gping.ps1 - Version 1.07
# Script to monitor connectivity of specified hosts
# Refreshes every 10 seconds and displays the status in a table

# Define the list of hosts to monitor
$hosts = @("POS1", "POS2", "POS3", "POS4")

# Initialize a hashtable to store the last seen timestamps
$lastSeen = @{}

# Function to retrieve IP and MAC address for a host
function Get-NetworkDetails {
    param (
        [string]$ComputerName
    )

    try {
        $pingResult = Test-Connection -ComputerName $ComputerName -Count 1 -ErrorAction Stop
        $arpTable = Get-NetNeighbor | Where-Object { $_.State -eq "Reachable" -and $_.IPAddress -eq $pingResult.Address.IPAddressToString }
        $macAddress = if ($arpTable) {
            $arpTable.LinkLayerAddress
        } else {
            "N/A"
        }

        return [pscustomobject]@{
            IPAddress = $pingResult.Address.IPAddressToString
            MACAddress = $macAddress
        }
    } catch {
        return [pscustomobject]@{
            IPAddress = "N/A"
            MACAddress = "N/A"
        }
    }
}

# Inform the user of the initialization process
Clear-Host
Write-Host "Initializing the script..." -ForegroundColor Cyan
Write-Host "Checking connectivity and network settings for hosts:" -ForegroundColor Cyan
$hosts | ForEach-Object { Write-Host " - $_" -ForegroundColor Yellow }
Write-Host "Please wait..." -ForegroundColor Cyan
Start-Sleep -Seconds 3

# Infinite loop to continuously check host statuses
while ($true) {
    # Process each host and capture their status
    $results = $hosts | ForEach-Object {
        # Get network details
        $networkDetails = if (Test-Connection $_ -Count 1 -Quiet) {
            Get-NetworkDetails -ComputerName $_
        } else {
            [pscustomobject]@{
                IPAddress = "N/A"
                MACAddress = "N/A"
            }
        }

        # Ping the host and check if it's reachable
        $ping = Test-Connection $_ -Count 1 -Quiet

        # Update the last seen timestamp if the host is reachable
        $lastSeen[$_] = if ($ping) {
            (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        } else {
            $lastSeen[$_]
        }

        # Determine the status
        [pscustomobject]@{
            Host       = $_
            IPAddress  = $networkDetails.IPAddress
            MACAddress = $networkDetails.MACAddress
            Status     = if ($ping) {
                "Connected"
            } elseif (-not $lastSeen[$_]) {
                "Not Connected, Never Seen"
            } else {
                "Not Connected"
            }
            LastSeen   = $lastSeen[$_]
        }
    }

    # Clear the console and display the results with color coding
    Clear-Host
    Write-Host ("{0,-10} {1,-15} {2,-20} {3,-25} {4}" -f "Host", "IP Address", "MAC Address", "Status", "Last Seen") -ForegroundColor Cyan
    Write-Host ("{0,-10} {1,-15} {2,-20} {3,-25} {4}" -f "----", "----------", "-----------", "------", "---------")

    $results | ForEach-Object {
        $color = switch ($_.Status) {
            "Connected" { "Green" }
            "Not Connected, Never Seen" { "Gray" }
            "Not Connected" { "Yellow" }
        }
        Write-Host ("{0,-10} {1,-15} {2,-20} {3,-25} {4}" -f $_.Host, $_.IPAddress, $_.MACAddress, $_.Status, $_.LastSeen) -ForegroundColor $color
    }

    # Countdown timer for refresh
    Write-Host "" # Blank line for spacing
    for ($i = 10; $i -gt 0; $i--) {
        Write-Host ("Refreshing in $i seconds..." -f $i) -ForegroundColor Yellow -NoNewline
        Start-Sleep -Seconds 1
        Write-Host "`r " -NoNewline
    }

    # Clear the countdown line and indicate refreshing
    Write-Host "`r `r`n" -NoNewline  # Clear the line completely
    Write-Host "Refreshing now..." -ForegroundColor Green
    Start-Sleep -Milliseconds 500
}
