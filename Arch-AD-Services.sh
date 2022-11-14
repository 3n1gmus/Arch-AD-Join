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
