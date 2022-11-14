#!/bin/bash
if[ $1,, == "start" ]
then
func1="enable"
func2="start"
else
func1="disable"
func2="stop"
fi

# Enable Services
systemctl $func1 ntpd.service
systemctl $func1 smb.service
systemctl $func1 nmb.service
systemctl $func1 winbind.service

# Start Services
systemctl $func2 ntpd.service
systemctl $func2 smb.service
systemctl $func2 nmb.service
systemctl $func2 winbind.service
