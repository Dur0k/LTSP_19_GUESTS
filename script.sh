#!/bin/bash
echo "Starting script"
teacher="lehrer"
pw_teacher="123456"
basename="guest"
pw_basename="guest"
# does the system have two NICs, one facing the clients, one the internet? if yes then put 0.
proxy_dhcp=0


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
cat >/etc/ltsp/ltsp.conf <<EOL
# /bin/sh -n
# LTSP configuration file
# Documentation=man:ltsp.conf(5)

# The special [server] section is evaluated only by the ltsp server
[server]
# Enable NAT on dual NIC servers
# NAT=1
# Provide a full menu name for x86_32.img when `ltsp ipxe` runs
# IPXE_X86_32_IMG="Debian Buster"

# The special [common] section is evaluated by both the server and ltsp clients
[common]
# Specify an alternative TFTP_DIR
# TFTP_DIR=/var/lib/tftpboot

# In the special [clients] section, parameters for all clients can be defined.
# Most ltsp.conf parameters should be placed here.
[clients]
FSTAB_NFS="SERVER_IP:/home/nfs /home nfs defaults,nolock 0 0"
AUTOLOGIN="ltsp/guest"
RELOGIN=1
PASSWORDS_GUEST="guest/guest"
POST_INIT_link="ln -s /etc/ltsp/guest.desktop /usr/share/xsessions/guest.desktop"

[5c:9a:d8:67:09:3f]
PWMERGE_SUR="lehrer"
EOL

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

cat >/etc/ltsp/setupsession.sh <<EOL
#!/bin/bash
rm -R /home/${USER}; mkdir -p /home/${USER}; rsync -rtvp /etc/ltsp/template/ /home/${USER}; chown -R ${USER}:${USER} /home/${USER}
startxfce4
EOL
