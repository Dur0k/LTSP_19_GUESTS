#!/bin/bash
#remove netplan and replace it with ifupdown and set up interfaces for ltsp
iface_inet="ens3"
iface_clients="dummy"

red=`tput setaf 1`
green=`tput setaf 2`
whiteback=`tput sgr 0`
reset=`tput sgr0`

# install ifupdown
echo "${green}Installing ifupdown${reset}"
apt install ifupdown

cat >/etc/network/interfaces <<EOL
# The loopback network interface
auto lo
iface lo inet loopback

# The server/internet facing interface
allow-hotplug $iface_inet
auto $iface_inet
iface $iface_inet inet dhcp

# The client serving interface with static address
allow-hotplug $iface_clients
auto $iface_clients
iface $iface_clients inet static
 address 192.168.67.1
 netmask 255.255.255.0
 broadcast 192.168.67.255
 gateway 192.168.67.1
EOL

echo "${green}Enabling ifupdown${reset}"
ifdown --force $iface_inet lo && ifup -a
systemctl unmask networking
systemctl enable networking
systemctl restart networking

echo "${green}Stopping and removing netplan${reset}"
systemctl stop systemd-networkd.socket systemd-networkd networkd-dispatcher systemd-networkd-wait-online
systemctl disable systemd-networkd.socket systemd-networkd networkd-dispatcher systemd-networkd-wait-online
systemctl mask systemd-networkd.socket systemd-networkd networkd-dispatcher systemd-networkd-wait-online
apt-get --assume-yes purge nplan netplan.io

echo "${green}Setting DNS server${reset}"
cat >/etc/systemd/resolved.conf <<EOL
#  This file is part of systemd.
#
#  systemd is free software; you can redistribute it and/or modify it
#  under the terms of the GNU Lesser General Public License as published by
#  the Free Software Foundation; either version 2.1 of the License, or
#  (at your option) any later version.
#
# Entries in this file show the compile time defaults.
# You can change settings by editing this file.
# Defaults can be restored by simply deleting this file.
#
# See resolved.conf(5) for details

[Resolve]
DNS=1.1.1.1
DNS=1.0.0.1
EOL

echo "${green}Rebooting${reset}"
systemctl restart systemd-resolved
reboot
