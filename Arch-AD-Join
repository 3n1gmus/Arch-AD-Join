#!/bin/bash

# Install Prerequisites
pacman -S --needed samba smbclient ntp krb5 cups --noconfirm

# Create Original Configuration Backup Folder
sudo mkdir /etc/orig_config

# Import Configuration
DC_Servers=()
for line in `cat ad.config`; do
    # echo $line
    IFS="=" read -a Info <<< $line
    case ${Info[0]} in
      NetBIOS)
        Netbios=${Info[1]}
        ;;
      DNS)
        DNS=${Info[1]}
        Kerberos=${Info[1]^^}
        ;;
      DC)
        IFS=";" read -a IP_Test <<< ${Info[1]}
        if [ -z "${IP_Test[1]}"]
          then
            echo "${Info[1]} has no IP address listed, Aborting"
            exit 1
          else
                  DC_Servers+=(${Info[1]})
        fi
        ;;
       *)
        ;;
    esac
done

# Create <Config> file
sudo mv /etc/apt/apt.conf.d/50unattended-upgrades /etc/orig_config/50unattended-upgrades.original
sudo touch /etc/apt/apt.conf.d/50unattended-upgrades
echo "Unattended-Upgrade::Allowed-Origins {" | sudo tee -a /etc/apt/apt.conf.d/50unattended-upgrades
echo "        \"\${distro_id}:\${distro_codename}\";" | sudo tee -a /etc/apt/apt.conf.d/50unattended-upgrades
echo "        \"\${distro_id}:\${distro_codename}-security\";" | sudo tee -a /etc/apt/apt.conf.d/50unattended-upgrades
echo "        \"\${distro_id}ESMApps:\${distro_codename}-apps-security\";" | sudo tee -a /etc/apt/apt.conf.d/50unattended-upgrades
echo "        \"\${distro_id}ESM:\${distro_codename}-infra-security\";" | sudo tee -a /etc/apt/apt.conf.d/50unattended-upgrades
echo "//Specific Settings" | sudo tee -a /etc/apt/apt.conf.d/50unattended-upgrades
echo "Unattended-Upgrade::Package-Blacklist {};" | sudo tee -a /etc/apt/apt.conf.d/50unattended-upgrades
echo "Unattended-Upgrade::DevRelease \"auto\";" | sudo tee -a /etc/apt/apt.conf.d/50unattended-upgrades
echo "Unattended-Upgrade::Automatic-Reboot \"true\";" | sudo tee -a /etc/apt/apt.conf.d/50unattended-upgrades
echo "Unattended-Upgrade::Automatic-Reboot-WithUsers \"true\";" | sudo tee -a /etc/apt/apt.conf.d/50unattended-upgrades
echo "Unattended-Upgrade::Automatic-Reboot-Time \"02:00\";" | sudo tee -a /etc/apt/apt.conf.d/50unattended-upgrades
