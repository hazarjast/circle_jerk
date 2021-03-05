## PowerShell: Script To Telnet To Remote Hosts And Run Commands Against Them With Output To A File ##

## Install TFTP client if not already present and allow through firewall
function InstallTFTP
{
  $tftp = ( Get-WindowsOptionalFeature -Online -FeatureName tft* )

  if ( $tftp.State -ne "Enabled" ) {
    trap { Write-Error "Could not install required TFTP feature!"; exit }
    Enable-WindowsOptionalFeature -Online -FeatureName $tftp.FeatureName -All | Out-Null
  }

  $fwrule = ( (New-object -ComObject HNetCfg.FWPolicy2).rules | where-object {$_.ApplicationName -match ".*TFTP.EXE"} )

  if ( ! $fwrule ) {
    trap { Write-Error "Could not add TFTP firewall rule!"; exit }
    New-NetFirewallRule -Program “C:\Windows\System32\TFTP.EXE” -Action Allow -Profile Domain, Private -DisplayName “Allow TFTP” -Description “TFTP” -Direction Outbound | Out-Null
  }
}

## Enable telnet on the router
function EnableTelnet
{
  $ip = $global:ip
  $mac = ((get-netneighbor | where-object {$_.IPAddress -eq $ip}).LinkLayerAddress).Replace("-", "")
  $password = (New-Object PSCredential "user",$global:password).GetNetworkCredential().Password

  trap { Write-Error "Could not enable telnet!"; exit }
  start-process -NoNewWindow ".\telnet-enable2.exe" -ArgumentList "$ip $mac admin $password"
}

## Read output from a remote host
function GetOutput
{
  ## Create a buffer to receive the response
  $buffer = new-object System.Byte[] 1024
  $encoding = new-object System.Text.AsciiEncoding
 
  $outputBuffer = ""
  $foundMore = $false
 
  ## Read all the data available from the stream, writing it to the
  ## output buffer when done.
  do
  {
    ## Allow data to buffer for a bit
    start-sleep -m 1000
 
    ## Read what data is available
    $foundmore = $false
    $stream.ReadTimeout = 1000
 
    do
    {
      try
      {
        $read = $stream.Read($buffer, 0, 1024)
 
        if($read -gt 0)
        {
          $foundmore = $true
          $outputBuffer += ($encoding.GetString($buffer, 0, $read))
        }
      } catch { $foundMore = $false; $read = 0 }
    } while($read -gt 0)
  } while($foundmore)
 
  $outputBuffer
}
 
function AutoTelnet(

    [string] $remoteHost = $global:ip, 
    [int] $port = 23,
    [string] $username = "admin",
    [string] $password = (New-Object PSCredential "user",$global:password).GetNetworkCredential().Password,
    [string] $command = "",
    [int] $commandDelay = 1000
)
{
  [string] $output = ""

  ## Open the socket, and connect to the computer on the specified port

  write-host "Connecting to $remoteHost on port $port"
 
  trap { Write-Error "Could not connect to remote computer: $_"; exit }
  $socket = new-object System.Net.Sockets.TcpClient($remoteHost, $port)
 
  write-host "Connected and running command..."
 
  $stream = $socket.GetStream()
 
  $writer = new-object System.IO.StreamWriter $stream

    ## Receive the output that has buffered so far
    $SCRIPT:output += GetOutput

        $writer.WriteLine($username)
        $writer.Flush()
        Start-Sleep -m $commandDelay
                $writer.WriteLine($password)
        $writer.Flush()
        Start-Sleep -m $commandDelay
                $writer.WriteLine($command) #Add additional entries below here for additional 'strings' you created above
        $writer.Flush()
        Start-Sleep -m $commandDelay
        $output += GetOutput
                
 
 
  ## Close the streams
  $writer.Close()
  $stream.Close()
 
  $output >> autotelnet_log.txt
}

## Upload file to router
function AutoTFTP
{
  $ip = $global:ip
  
  trap { Write-Error "Could not upload the install package to router!"; exit }
  start-process -NoNewWindow "C:\Windows\System32\TFTP.EXE" -ArgumentList "-i $ip PUT circle_jerk.zip"
}

## Main execution block
function Main
{
  $global:ip = ((Get-NetIPConfiguration).IPv4DefaultGateway).NextHop
  $global:password = read-host -AsSecureString "Enter the router's 'admin' password"
  $ip = $global:ip

  InstallTFTP
  EnableTelnet
  AutoTelnet -command "touch /var/tftpd-hpa/circle_jerk.zip ; chmod 777 /var/tftpd-hpa/circle_jerk.zip"
  AutoTFTP
  AutoTelnet -command "unzip /var/tftpd-hpa/circle_jerk.zip -d /mnt/circle/ ; rm -f /var/tftpd-hpa/circle_jerk.zip ; /mnt/circle/mods/circle_jerk_install"

  $hash = (([string](new-object System.Security.Cryptography.SHA256Managed | ForEach-Object {$_.ComputeHash([System.Text.Encoding]::UTF8.GetBytes((New-Object PSCredential "user",$global:password).GetNetworkCredential().Password))} | ForEach-Object {$_.ToString("x2")})).ToUpper()).Replace(" ", "")

  write-host "Circle has been modded! Now you must login to your router and enable Circle (under 'Parental Controls' menu item) then click 'Apply'."
  write-host "Once Circle has been enabled, you can then SSH into your router at $ip with username 'root' and the following password:"
  write-host "$hash"
}

. Main