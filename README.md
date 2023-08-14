## Debian Ubuntu Raspberry Pi Linux Message of the Day (MOTD) banner with system information

### Tested with the following systems
* Debian 11
* Ubuntu 22.04 LTS
* FreeBSD 13 (currently limited display options)

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

System Hostname...: debian01
System Date/Time..: Mon, 14 August 2023, 12:05:45 PM
System Uptime.....: 3 hours, 34 minutes
System OS.........: Debian GNU/Linux 12 (bookworm)
System Kernel.....: 6.1.0-11-amd64
System Arch.......: x86_64
System Proc.......: 13th Gen Intel(R) Core(TM) i7-13700K
Memory Usage......: 2199MB/64068MB (3%)
Storage /.........: 380GB/982GB (36%)
Storage /boot.....: 183MB/478MB (35%)
Storage /boot/efi.: 37MB/536MB (7%)
Network eth0......: 192.168.1.10
Ext. IP Address...: 12.34.56.78
Ext. IP Location..: City Region CountryCode
Ext. IP ORG/ISP...: Provide / ISP Information


Raspberry Pi will display processor as follows - 
System Proc.......: Raspberry Pi 4 Model B Rev 1.1
```


### Usage Quick Install

The following applies to Debian and Raspberry Pi
```terminal
# Download `motd.sh` as `00-motd` into `/etc/update-motd.d/` directory and set permissions.
sudo wget -qO /etc/update-motd.d/00-motd https://raw.githubusercontent.com/bradsec/motd/main/motd.sh &&\
sudo chmod 755 /etc/update-motd.d/00-motd

# Rename default motd (applies to Debian and Raspberry Pi not Ubuntu) 
sudo mv /etc/motd /etc/motd.original

# Disable any other scripts in `/etc/update-motd.d/` apart from the new `00-motd`  
sudo chmod -x /etc/update-motd.d/* &&\
sudo chmod +x /etc/update-motd.d/00-motd &&\

# Update the SSH config to prevent last user login information being displayed.
sudo sed -i 's/#PrintLastLog yes/PrintLastLog no/' /etc/ssh/sshd_config &&\
sudo sed -i 's/PrintLastLog yes/PrintLastLog no/' /etc/ssh/sshd_config &&\
sudo systemctl restart ssh
```

### Notes / Troubleshooting
- The ipinfo.io lookup delays the execution and login slightly.
- Comment out in the `sys_info()` function to disable this function.
- Ubuntu by default may be missing `ifconfig` and no display network interface IP information.
- Simply install net-tools using `sudo apt install net-tools`  

