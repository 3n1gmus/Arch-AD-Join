#!/bin/bash
op=$1
if[ ${op,,} == "start" ]
then
  func1="enable"
  func2="start"
else
  func1="disable"
  func2="stop"
fi

# Enable Services
sudo systemctl $func1 ntpd.service
sudo systemctl $func1 smb.service
sudo systemctl $func1 nmb.service
sudo systemctl $func1 winbind.service

# Start Services
sudo systemctl $func2 ntpd.service
sudo systemctl $func2 smb.service
sudo systemctl $func2 nmb.service
sudo systemctl $func2 winbind.service
