# monitor_vpn
Simple powershell script to monitor Windows 11 built in VPN

Set the name of your VPN to reconnect to in $vpnName

The script will check if it is connected to the VPN. It will try to automatically reconnect if it disconnects.
After 5 attempts, if the script is run as admin, it will disable your ethernet adapter.
