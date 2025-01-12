$vpnName = "VPN"  # Replace with your VPN connection name
$networkAdapterName = ""  # Replace with the name of the network adapter you want to disable or it will disable the first one listed in Get-NetAdapter that is up
$retryAttempts = 5  # Number of retry reconnection attempts to the VPN

# Check if running as admin for disabling Network adapter
$principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
$hasAdminRights = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if ($hasAdminRights) {
    Write-Host "Ethernet adapter will be disabled after 5 failed reconnection attempts."
} else {
    Write-Host "Insufficient permissions to disable network adapter after 5 failed reconnection attempts."
}

# Function to check if VPN is connected
function Check-VPN {
    return (rasdial | Select-String -Pattern "Connected to") -ne $null
}

# Function to connect to VPN
function Connect-VPN {
    Write-Host "Attempting to connect to $vpnName"
    rasdial $vpnName
    if (Check-VPN) {
        Write-Host "Successfully connected to $vpnName"
    } else {
        Write-Host "Failed to connect to $vpnName"
    }
}

# Initial VPN check and attempt to connect if not connected
if (-not (Check-VPN)) {
    Connect-VPN
} else {
    Write-Host "$vpnName is connected."
}

# Monitor VPN status in a loop
Write-Host "Monitoring VPN connection. Press Ctrl + C to stop the script."
try {
    while ($true) {
        if (Check-VPN) {
            Start-Sleep -Seconds 1  # Sleep for 1 second if VPN is connected
        } else {
            Write-Host "$vpnName disconnected. Attempting to reconnect..."
            $reconnectAttempts = 0
            while ($reconnectAttempts -lt $retryAttempts) {
                Connect-VPN
                if (-not (Check-VPN)) {
                    $reconnectAttempts++
                    Write-Host "Reconnection attempt $reconnectAttempts failed."
                    Start-Sleep -Seconds 5
                } else {
                    Start-Sleep -Seconds 1
                    break
                }
            }

            if ($reconnectAttempts -ge $retryAttempts) {
                Write-Host "All reconnection attempts failed."
                if ($hasAdminRights) {
                    
                    if (-not $networkAdapterName) { 
                        $networkAdapter = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }
                        $networkAdapterName = $networkAdapter.Name
                    }
                    
                    if ($networkAdapterName -and (Get-NetAdapter -Name $networkAdapterName -ErrorAction SilentlyContinue)) {
                        Disable-NetAdapter -Name $networkAdapterName -Confirm:$false
                        Write-Host "Network adapter '$networkAdapterName' has been disabled."
                        exit
                    } else {
                        Write-Host "No network adapter '$networkAdapterName' found."
                        exit
                    }
                } else {
                    Write-Host "Insufficient permissions to disable network adapter."
                    exit
                }
            }
        }
    }
}
catch {
    Write-Host "Script has been stopped."
}
