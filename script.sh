#!/bin/bash
echo "Starting script"
teacher="lehrer"
pw_teacher="123456"
basename="guest"
pw_basename="guest"
# does the system have two NICs, one facing the clients, one the internet? if yes then put 0.
proxy_dhcp=0
nfs_ip=""

red=`tput setaf 1`
green=`tput setaf 2`
whiteback=`tput sgr 0`
reset=`tput sgr0`


echo "${green}Adding ppa${reset}"
# add ltsp ppa
add-apt-repository -y ppa:ltsp
apt update

echo "${green}Removing problematic packages${reset}"
# remove problematic packages
apt purge --yes --auto-remove indicator-application mate-hud snapd
apt install --yes synaptic

echo "${green}Installing ltsp server packages${reset}"
# install ltsp server packages
apt install --yes ltsp dnsmasq nfs-kernel-server openssh-server squashfs-tools ethtool net-tools epoptes 

wget -O /tmp/greenfoot.deb http://www.greenfoot.org/download/files/Greenfoot-linux-360.deb
dpkg -i /tmp/greenfoot.deb

echo "${green}Setup dnsmasq${reset}"
# setup dnsmasq
ltsp dnsmasq --proxy-dhcp=$proxy_dhcp

echo "${green}Install client packages${reset}"
# install client packages
apt install --yes rsync xubuntu-desktop vlc gimp pinta libreoffice scratch geogebra nemo

echo "${green}Set system locale${reset}"
# Change system locale
cat >/etc/default/locale <<EOL
LANG=de_DE.UTF-8
LANGUAGE=de_DE
LC_ALL=de_DE.UTF-8
EOL

locale-gen

echo "${green}Download german language packages${reset}"
# Download german language packages
apt -y install $(check-language-support -l de)

echo "${green}Create client image${reset}"
# create client image
ltsp image /

echo "${green}Create iPXE entry${reset}"
# create iPXE entry
ltsp ipxe

echo "${green}Setup NFS share${reset}"
# configure nfs share for home folders
ltsp nfs --nfs-home=1

echo "${green}Create ltsp.conf${reset}"
# create ltsp.conf
install -m 0660 -g sudo /usr/share/ltsp/common/ltsp/ltsp.conf /etc/ltsp/ltsp.conf

# overwrite it
cp ltsp.conf /etc/ltsp/ltsp.conf

echo "${green}Add accounts${reset}"
# Add a teacher account
adduser $teacher --disabled-password --gecos ""
echo -e "$pw_teacher\n$pw_teacher\n" | sudo passwd $teacher
gpasswd -a $teacher epoptes
gpasswd -a ${SUDO_USER:-$USER} epoptes

# Add user accounts
mkdir /home/nfs

for ip in {20..250}; do
    ltspuser="${basename}${ip}"
    adduser $ltspuser --disabled-password --gecos ""
    echo -e "$pw_basename\n$pw_basename\n" | sudo passwd $ltspuser
    mv "/home/${ltspuser}" /home/nfs/
    ln -s "nfs/${ltspuser}" "/home/${ltspuser}"
done

echo "${green}Create guest session${reset}"
# create guest session
cat >/etc/ltsp/guest.desktop <<EOL
[Desktop Entry]
Name=Guest Session
Name[de]=Gast Sitzung
Comment=Use this session to run a guest session as your environment
Exec=/etc/ltsp/setupsession.sh
Type=Application
DesktopNames=GUEST
EOL

cp setupsession.sh /etc/ltsp/setupsession.sh

chmod +x /etc/ltsp/setupsession.sh

echo "${green}Downloading template${reset}"
wget -O /etc/ltsp/template.tar.gz https://durok.tech/gitea/durok/LTSP_19_GUESTS/raw/branch/master/template.tar.gz
tar xvf /etc/ltsp/template.tar.gz --directory /etc/ltsp/
rm /etc/ltsp/template.tar.gz
