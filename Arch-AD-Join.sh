#!/bin/bash

Archive_File () {
        if [ -f $1 ]
        then
                Archive_Path="/etc/orig_config"
                EpocTime=`date +"%s"`
                [ ! -d $Archive_Path ] && mkdir -p $Archive_Path
                Source=$1
                IFS="/" read -a Path <<< $Source
                Destination="$Archive_Path/${Path[-1]}.original"
                if [ -f $Destination ]
                then
                        Destination="$Archive_Path/${Path[-1]}.${EpocTime}"
                fi
                echo "Moving $Source to $Destination"
                sudo mv $Source $Destination
        else
                echo "$1 does not exist."
        fi
}

# Install Prerequisites
pacman -S --needed samba smbclient ntp krb5 cups --noconfirm

# Create Original Configuration Backup Folder
# sudo mkdir /etc/orig_config

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

# Create NTP Configuration
config_file="/etc/ntp.conf"
Archive_File $config_file
config="./arch-ntp.conf"
sudo echo "# NTP Servers" >> $config_file

for line in ${DC_Servers[@]}; do
        IFS=";" read -a Info <<< $line
        sudo echo "server ${Info[0]}" >> $config_file
done
sudo echo "server 0.us.pool.ntp.org" >> $config_file
sudo echo "" >> $config_file
while read -r line; do
    echo "$line" >> $config_file
done <$config

# Enable NTP
systemctl enable ntpd.service

# Create krb5 configuration
config_file="/etc/krb5.conf"
Archive_File $config_file
sudo echo "[libdefaults]" >> $config_file
sudo echo "   default_realm = $Kerberos" >> $config_file
sudo echo "   dns_lookup_realm = false" >> $config_file
sudo echo "   dns_lookup_kdc = true" >> $config_file
sudo echo "   default_ccache_name = /run/user/%{uid}/krb5cc" >> $config_file
sudo echo "" >> $config_file
sudo echo "[domain_realm]" >> $config_file
sudo echo "    .$DNS = $Kerberos" >> $config_file
sudo echo "" >> $config_file
sudo echo "[appdefaults]" >> $config_file
sudo echo "   pam = {" >> $config_file
sudo echo "        ticket_lifetime = 1d" >> $config_file
sudo echo "        renew_lifetime = 1d" >> $config_file
sudo echo "        forwardable = true" >> $config_file
sudo echo "        proxiable = false" >> $config_file
sudo echo "        minimum_uid = 1" >> $config_file
sudo echo "    }" >> $config_file
