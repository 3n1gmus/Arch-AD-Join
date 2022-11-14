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
RFC2307="false"
Printers="false"
ADuser="Administrator"

for line in `cat ad.config`; do
    # echo $line
    IFS="=" read -a Info <<< $line
    case ${Info[0]} in
      NetBIOS)
        # echo "NetBIOS: ${Info[1]^^}"
        Netbios=${Info[1]}
        ;;
      DNS)
        DNS=${Info[1]}
        Kerberos=${Info[1]^^}
        ;;
      DC)
        IFS=";" read -a IP_Test <<< ${Info[1]}
        if [ -z "${IP_Test[1]}" ]
          then
            echo "${Info[1]} has no IP address listed, Aborting"
            exit 1
          else
                  DC_Servers+=(${Info[1]})
        fi
        ;;
      RFC2307)
        if [ ${Info[1],,} == "true" ];
        then
                RFC2307="true"
        fi
        ;;
      Printers)
        if [ ${Info[1],,} == "true" ]
        then
                Printers="true"
        fi
        ;;
      ADuser)
                ADuser=${Info[1]}
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
while IFS= read -r line; do
    sudo echo "$line" >> $config_file
done <$config

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

# Create PAM System-auth
config_file="/etc/pam.d/system-auth"
EpocTime=`date +"%s"`
Destination="/etc/orig_config/system-auth.original"
if [ -f $Destination ]
then
        Destination="/etc/orig_config/system-auth.${EpocTime}"
fi
echo "Copying $config_file to $Destination"
sudo cp $config_file $Destination
config="arch-system-auth.conf"
temp="./tmp.file"
while IFS= read -r line; do
    sudo echo "$line" >> $temp
done <$config
sudo mv -f $temp $config_file

# Create PAM su file
config_file="/etc/pam.d/su"
Archive_File $config_file
config="arch-su.conf"
while IFS= read -r line; do
    sudo echo "$line" >> $config_file
done <$config

# Create pam_winbind file
config_file="/etc/security/pam_winbind.conf"
Archive_File $config_file
config="arch-pam_winbind.conf"
while IFS= read -r line; do
    sudo echo "$line" >> $config_file
done <$config

# Create nsswitch file
config_file="/etc/nsswitch.conf"
Archive_File $config_file
config="arch-nsswitch.conf"
while IFS= read -r line; do
    sudo echo "$line" >> $config_file
done <$config

# Create SMB configuration file
config_file="/etc/samba/smb.conf"
Archive_File $config_file

# Generated SMB config start
sudo echo "[global]" >> $config_file
sudo echo "   workgroup = $Netbios" >> $config_file
sudo echo "   security = ADS" >> $config_file
sudo echo "   realm = $Kerberos" >> $config_file

# Import SMB middle configuration
config="arch-smb-mid.conf"
while IFS= read -r line; do
    sudo echo "$line" >> $config_file
done <$config

# Configure RFC2307 SMB Configuration
if [ $RFC2307 == "true" ]
then
        sudo echo "   idmap config INTERNAL : backend = ad" >> $config_file
        sudo echo "   idmap config INTERNAL : schema_mode = rfc2307" >> $config_file
        sudo echo "   idmap config INTERNAL : range = 10000-999999" >> $config_file
        sudo echo "   idmap config INTERNAL : unix_nss_info = yes" >> $config_file
        sudo echo "" >> $config_file
else
        sudo echo "   idmap config INTERNAL : backend = rid" >> $config_file
        sudo echo "   idmap config INTERNAL : range = 10000-999999" >> $config_file
        sudo echo "" >> $config_file
fi

# Import SMB Middle2 configuration
config="arch-smb-mid2.conf"
while IFS= read -r line; do
    sudo echo "$line" >> $config_file
done <$config

# Configure SMB Printer Sharing
if [ $Printers == "false" ]
then
        sudo echo "" >> $config_file
        sudo echo "   # Disable Printer Sharing" >> $config_file
        sudo echo "   load printers = no" >> $config_file
        sudo echo "   printing = bsd" >> $config_file
        sudo echo "   printcap name = /dev/null" >> $config_file
        sudo echo "   disable spoolss = yes" >> $config_file
        sudo echo "" >> $config_file
fi

# Import SMB tail configuration
config="arch-smb-tail.conf"
while IFS= read -r line; do
    sudo echo "$line" >> $config_file
done <$config

# Update /etc/hosts
hostname=$(hostname)
FQDN=$hostname.$DNS
entry="$hostname.$DNS $hostname"
sudo sed -i 's/$hostname/$entry/g' /etc/hosts

# join domain
sudo net ads join -U $ADuser

# Enable Services
systemctl enable ntpd.service
systemctl enable smb.service
systemctl enable nmb.service
systemctl enable winbind.service

# Start Services
systemctl start ntpd.service
systemctl start smb.service
systemctl start nmb.service
systemctl start winbind.service
