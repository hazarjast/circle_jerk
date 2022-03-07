# circle_jerk
Hijacking the Circle feature in Netgear's LBR20 router to do our bidding.
Tested on firmware 2.6.3.50.

[b]***'CIRCLE_JERK' AUTO DEPLOYMENT TROUBLESHOOTING AND MANUAL DEPLOYMENT INSTRUCTIONS***[/b]
Thank you to those that have tested automatic deployment via 'deploy_circle_jerk.ps1' and provided feedback. Some troubleshooting help and manual deployment instructions can be found below:

[list]
[*][i]Mind Your SKU[/i]
The .ps1 script has only been tested on a fresh US Retail model SKU LBR20-100NAS on firmware v2.6.3.50. You won't find this SKU designation on the label since Netgear seems to be stealth about their SKU variations but if you bought the unit through Amazon US or Netgear US then it should be this SKU. There are other North American SKUs for the device such as the US Cellular and Bell Mobility. If you don't have a US Retail unit, you may have to use the manual deployment instructions below this troubleshooting list. A partial list of current device SKUs can be found here:
[url]https://kb.netgear.com/000062073/What-cellular-bands-are-supported-by-LBR20[/url]
[*][i]Mind Your Firmware Source[/i]
There have been indications from at least one user that the firmware provided by the gui update feature appears to be a somewhat different variant than the one provided for manual download on Netgear's US support site. For clarity, the one I tested on came directly from the following link:
[url]https://www.downloads.netgear.com/files/GDC/LBR20/LBR20_V2.6.3.50.zip[/url]
Google Drive mirror of the same here:
[url]https://drive.google.com/file/d/1lbOeSOP5bdFgvhcEsKWMClY43bc86Qq5/view?usp=sharing[/url]
[*][i]Start With a Fresh Slate[/i]
Along with using the firmware from the previous point, it is recommended to factory reset prior to attempting auto-deployment to be sure no non-default config will cause an issue during the deployment process. If you have two 'sliders' under 'Parental Controls' then you are likely not starting with a fresh slate.
[*][i]Mind Your Network Interfaces[/i]
This script assumes only one network adapter is active and connected directly to the LBR20 LAN (br0) interface. If you have other network interfaces (whether physical or virtual) you may need to disable them under Windows Device Manager in order for the deployment script to be able to detect the LBR20's IP and MAC address properly. A common indicator that you have more than one network interface active is if the 'telnet-enable2.exe' step fails in the script with an error similar to the following:
[code]
EnableTelnet : Could not enable telnet!
At D:\circle_jerk-main\deploy_circle_jerk.ps1:136 char:3
+   EnableTelnet
+   ~~~~~~~~~~~~
    + CategoryInfo          : NotSpecified: (:) [Write-Error], WriteErrorException
    + FullyQualifiedErrorId : Microsoft.PowerShell.Commands.WriteErrorException,EnableTelnet
[/code]
If you cannot disable interfaces which are not the one connected to the LBR20 then I would recommend using the manual deployment instructions.
[*][i]Addressing Windows Defender Exclusion Issues[/i]
If you try to add the Windows Defender exclusions via the 'circle_jerk_defender_exclusions.reg' file and get an error saying that the registry was locked or you didn't have proper permission, be sure that you don't have Defender / Security Center open and/or actively running a scan. Try rebooting or temporarily stopping Defender ('Security Center > Virus and Threat Protection > Manage Settings > Real-time protection > Off'), or just add the process exceptions manually for 'telnet-enable2.exe' and 'deploy_circle_jerk.ps1' ('Security Center > Virus and Threat Protection > Manage Settings > Exclusions > Add or remove exclusions > Add an exclusion > Process'). If you do decide to temporarily disable Windows Defender entirely please go back and add the manual process exclusions and re-enable Defender afterwards. I do not want to see anyone get a virus because they failed to re-enable protection :)
[*][i]Check the Script Output[/i]
The script should produce output similar to the below screenshot:
[img]https://lh3.googleusercontent.com/TmUgafZ3vwtJ-W43jGuH9CKpqOltlCA-TsjSuKUMJRI81VKdDLETl8rz76C1bjQu5hCh0aCt8RQgEFsj-gLkQGvzc1jeWYC8YkNn-cmvcyiEPFK_pI_U7knATiKNf2fZz2fMP1-CESs=w2400[/img]
If you are missing one of the 'telnet' lines or 'transfer successful' lines then telnet commands or TFTP transfer may have not occurred. If telnet commands are missing or came back with an error, check the 'autotelnet_log.txt' file in the current directory to see if it provides any clues to the failure. If TFTP 'transfer successful' line is missing, try running 'TFTP -i [LBR20_IP] PUT circle_jerk.zip' manually from the same directory to see if it comes back with any errors. A common issue would be TFTP failing to connect to the LBR20 in case the outbound 'allow' rule for it failed to be created by the script or the rule was disabled/removed by accident.
[*][i]Try a Restart[/i]
If the deployment script seems to have executed successfully but you cannot access SSH after enabling/applying Circle in the web gui, restart the router and see if SSH is available after 5-10 minutes.
[*][i]Deploy Manually[/i]
If your issue is not covered above or you still have issues after following the aforementioned troubleshooting directions, then it will likely be less hassle for you to deploy the mod manually as outlined below.
[/list]

[b]***'CIRCLE_JERK' MANUAL DEPLOYMENT INSTRUCTIONS***[/b]
[list=1]
[*]Create Windows Defender exception for 'telnet-enable2.exe': 'Security Center > Virus and Threat Protection > Manage Settings > Exclusions > Add or remove exclusions > Add an exclusion > Process > telnet-enable2.exe'.
[*]Install Windows TFTP client. From Windows search bar, search for 'Windows Features' and select the result which says "Turn Windows features on or off". Scroll down to "TFTP Client" and click in the box next to it to select it then click 'OK'. Windows will install TFTP Client.
[*]Add a windows firewall rule to allow the application 'C:\Windows\System32\TFTP.exe' outbound firewall access. Or create an 'allow' rule for outbound on port 69. By default Windows will block outbound communication to TFTP port 69 so either one of these rules will allow this.
[*]From an Administrator command or powershell prompt in the folder you you extracted the circle_jerk files to, execute the following command (where '[IP]' is the IP address of the LBR20, '[MAC]' is the uppercase MAC address of the router's LAN (br0) interface with any separation characters (':' or '-') removed and '[PASSWORD]' is your web gui 'admin' password):
[code].\telnet-enable2.exe [IP] [MAC] admin [PASSWORD][/code]
[*]Use Putty or Windows' telnet client to telnet into the device and execute the following command:
[code]touch /var/tftpd-hpa/circle_jerk.zip ; chmod 777 /var/tftpd-hpa/circle_jerk.zip[/code]
[*]From the command or powershell prompt you already had open from executing 'telnet-enable2.exe', issue the following TFTP command to upload the 'circle_jerk.zip' package to the router (where '[IP]' is the ip address of the LBR20):
[code]tftp -i [IP] PUT circle_jerk.zip[/code]
[*]From your telnet session, execute the following command:
[code]unzip /var/tftpd-hpa/circle_jerk.zip -d /mnt/circle/ ; rm -f /var/tftpd-hpa/circle_jerk.zip ; /mnt/circle/mods/circle_jerk_install[/code]
(the above may be line-wrapped in your browser and/or when pasted into your telnet session, but it is in fact all a single line and should be entered/executed as such)
[*]Enable Circle under 'Parental Controls' in the web gui. Once this is complete, the SSH daemon will be ready to connect to and TTL mangle / hosts file mods will run every 4 minutes thereafter. You can now SSH into the unit and make any desired modifications to the scripts under '/mnt/circle/mods'. If not, reboot the router and wait 5-10 then try SSH again.
[*]Replace '[PASSWORD]' in the following command with your plaintext 'admin' password, then exute it at a powershell prompt to obtain your 'root' SSH password:
[code](([string](new-object System.Security.Cryptography.SHA256Managed | ForEach-Object {$_.ComputeHash([System.Text.Encoding]::UTF8.GetBytes(("[PASSWORD]")))} | ForEach-Object {$_.ToString("x2")})).ToUpper()).Replace(" ", "")[/code]
[/list]
As a final note, if you're not comfortable creating Windows Defender exclusions for the 'telnet-enable2.exe' provided in the 'circle_jerk' deployment repository, you don't have to use it. All that it is, is a 'pyinstaller' compiled version of the source Python script from which it was created. If you have an updated version of Python 3 already available on your PC you can execute the Python script directly instead:
[url]https://raw.githubusercontent.com/bkerler/netgear_telnet/main/telnet-enable2.py[/url]

[b]***v2.6.3.50 MOD (AKA 'CIRCLE_JERK') AUTO DEPLOYMENT INSTRUCTIONS***[/b]
The 'circle_jerk' mod package can be found on its GitHub repository page (the instructions that follow assume a Windows 10 client PC is being used which is directly connected to the LBR20 via Ethernet with no other LAN connections present):
[url]https://github.com/hazarjast/circle_jerk[/url]

[list=1]
[*]At the top of the repository page look for the green "Code" button to click and you will have the option to "Download .ZiP".
[*]Once downloaded/extracted, double-click the 'circle_jerk_defender_exclusions.reg' file to add its content to your registry. This is required since Windows Defender views my PowerShell code as malicious and will delete it along with 'telnet-enable2.exe' if you do not add process exclusions for it. If you have another antivirus installed you will need to add manual exclusions for processes 'deploy_circle_jerk.ps1' and 'telnet-enable2.exe'.
[*]Once .reg file is imported and/or any manual AV exclusions for the .ps1 and .exe process names have been added, you should open a new powershell prompt *as an administrator* in the same directory you extracted the 'circle_jerk' .zip package to, and issue the following command:
[i]Powershell -noprofile -executionpolicy bypass -file .\deploy_circle_jerk.ps1[/i]
[*]The script may take anywhere from a few seconds to a couple minutes to run its initial tasks but will eventually prompt you to enter your LBR20 'admin' web gui password. Once you have done this, hit 'Enter' and the script will activate telnet on the LBR20 and deploy the mod files to the unit.
[*]The script will inform you when the process is complete and will instruct you to now enable Circle under the web gui along with providing your unique SSH password (you should store this in a safe place as you'll need it any time you want to SSH into your LBR20).
[*]Enable Circle under 'Parental Controls' in the web gui. Once this is complete, the SSH daemon will be ready to connect to and TTL mangle / hosts file mods will run every 4 minutes thereafter. You can now SSH into the unit and make any desired modifications to the scripts under '/mnt/circle/mods'.
[/list]
On reboot the unit will wait for an active Internet connection (waiting for either the modem or WAN port to connect), then Circle will fire up and activate SSH again along with running your 'recurring' script every 4 minutes. If you disable Circle and reboot, the mod files will still be available but they will not run. If you wish to restore native Circle functionality simply factory reset the device. This won't erase the '/mnt/circle/mods' directory, but will restore the default circle scripts and you would need to manually run 'telnet-enable2.exe' in order to enable telnet and configure SSH/scripts to run again (else you could delete 'mods' folder entirely and run the powershell again to redeploy).

[b]'Circle_Jerk' Script Breakdown[/b]

[list]
[*][i]circle_jerk_install[/i]
This creates a backup of the Circle scripts it will overwrite, then overwrites them with symlinks back to 'circle_jerk'.
[*][i]circle_jerk[/i]
This script has 3 sections. In the first section 'call_once' commands are executed such as defining a new 'MOTD' banner and starting the SSH daemon. The second 'call_recurring' section calls commands which are executed every 4 minutes. The third and final 'call_end' section calls commands which are executed when Circle is disabled from the web gui such as killing the SSH daemon.
[*][i]call_once[/i]
Contains commands which are executed only once when Circle is enabled or the device boots up. By default this starts the dropbear SSH daemon and changes the 'MOTD' banner from the default Chaos Calmer one. Other examples of popular commands are given as examples but populated with example values only and commented out to prevent them from running unless you want them to.
[*][i]call_recurring[/i]
Contains commands which are executed only 4 minutes. These commands or calls to other scripts should vetted to make sure they are safe to call multiple times (i.e. the TTL mangle commands offered by default in the called 'fw_rules' script are executed in a pair of iptables commands: the first checks the presence of a rule while the second only adds a rule if it isn't found to be present by the first command). You don't want to just add any command here such as a single iptables command as this will 'stack' duplicate rules in iptables and cause slowdowns and an eventual crash when the device runs out of memory.
[*][i]call_end[/i]
Contains commands which are executed only when Circle is disabled in case you no longer wish for SSH to run or to toggle it in case of a dropbear or other troubleshooting issue.
[*][i]fw_rules[/i]
Contains iptables command pairs which check iptables for the presence of a rule then add it if it is not found. By default rules to harden SSH access from bruteforce attacks and those which mangle TTL are present (the SSH rules are probably overkill since SSH is bound by default to the IP of the 'br0' LAN interface but I wanted to provide extra security by default in case dropbear's 'start_db' script was modified by a user and no longer bound to listening on a single IP/interface).
[*][i]banner[/i]
Creates a fancy-pants ASCII art 'MOTD' to replace the default Chaos Calmer one.
[*][i]start_db[/i]
Located in the 'dropbear' subfolder of '/mnt/circle/mods', this script checks to see if dropbear is already running and if not, makes sure its certificate files are generated (if also not present). It also binds SSH to IPv4 'inet' address of the LAN ('br0' interface) and sets the root password to match that of the web gui 'admin' user (aka 'http_passwd_hashed').
[/list]
