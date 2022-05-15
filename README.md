## Debian Ubuntu Raspberry Pi Linux Message of the Day (MOTD) banner with system information

### Tested with the following systems
- Debian 11
- Ubuntu 22.04 LTS

### Sample output
```terminal

╔═════════════════════════════════════════════╗
║     YOU HAVE ACCESSED A PRIVATE SYSTEM      ║
║         AUTHORISED USER ACCESS ONLY         ║
║                                             ║
║ Unauthorised use of this system is strictly ║
║ prohibited and may be subject to criminal   ║
║ prosecution.                                ║
║                                             ║
║  ALL ACTIVITIES ON THIS SYSTEM ARE LOGGED.  ║
╚═════════════════════════════════════════════╝

System Date/Time..: Sunday,15 May 2022, 11:46:54 AM
System Uptime.....: 2 days, 19 hours, 54 minutes
System Hostname...: pi-10
System Host IP....: 192.168.1.10
System OS.........: Debian GNU/Linux 11 (bullseye)
System Kernel.....: 5.15.32-v8+
System Arch.......: aarch64
System Proc.......: Raspberry Pi 4 Model B Rev 1.1
Running Processes.: 219
Memory Usage......: 39%
Storage...........: sda1 Used: 12% Free: 221MB
Storage...........: sda2 Used: 36% Free: 550.8GB
External IP Info..: 12.34.56.78 host-78-56-34-12.com
                  : City Region CountryCode

```


### Usage

Download `motd.sh` as `00-motd` into `/etc/update-motd.d/` directory and set permissions.
```sh
sudo wget -O /etc/update-motd.d/00-motd https://raw.githubusercontent.com/bradsec/motd/main/motd.sh &&\
sudo chmod 755 /etc/update-motd.d/00-motd
```

Rename default motd located at /etc/motd
```sh
sudo mv /etc/motd /etc/motd.original
```

#### Optional
- Update the SSH config to prevent last user login information being displayed.
- Disable any other scripts in `/etc/update-motd.d/` apart from the new `00-motd`  
```sh
sudo sed -i 's/#PrintLastLog yes/PrintLastLog no/' /etc/ssh/sshd_config &&\
sudo sed -i 's/PrintLastLog yes/PrintLastLog no/' /etc/ssh/sshd_config &&\
sudo chmod -x /etc/update-motd.d/* &&\
sudo chmod +x /etc/update-motd.d/00-motd &&\
sudo systemctl restart ssh
```
- The ipinfo.io lookup delays the execution slightly.
- Comment out the `show_ipinfo` in the `sys_info()` function if you don't want external IP details or to speed up the script on login.  


