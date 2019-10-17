# Guest session for LTSP 19
## About
In the following a guest session for use with the Linux Terminal Server Project (LTSP) will be set up. Its goal is to assign each client computer a guest account based on the IP address. The home folder of the account will be deleted and recreated from a template. Afterwards the client will automatically log in with that account. For this to work a custom xsession will be created.

## LTSP installation
To install LTSP visit [Installation](https://github.com/ltsp/ltsp/wiki/installation).

## Guest session setup
This section contains the setup instructions and starts with changing [/etc/ltsp/ltsp.conf](https://github.com/ltsp/ltsp/blob/master/docs/ltsp.conf.5.md), sharing parts of the home folder via [ltsp nfs(8)](https://github.com/ltsp/ltsp/blob/master/docs/ltsp-nfs.8.md)
 and generating guest accounts. Then a custom xsession will be created which executes a script before starting the desktop environment.
 
### Configuring ltsp.conf
An initial `ltsp.conf` can be created with
```text
install -m 0660 -g sudo /usr/share/ltsp/common/ltsp/ltsp.conf /etc/ltsp/ltsp.conf
```

Now edit `/etc/ltsp/ltsp.conf` and add the following lines to the client section:

```text
[clients]
FSTAB_NFS="SERVER_IP:/home/nfs /home nfs defaults,nolock 0 0"
AUTOLOGIN="ltsp/guest"
RELOGIN=1
PASSWORDS_GUEST="guest/guest"
```

Change "SERVER_IP" to your NFS server address. The `FSTAB_NFS` line will mount the not yet configured `/home/nfs` NFS share to clients `/home`. By default each client computer gets a hostname consisting of "ltsp" and its IP address:
```text
ltsp${IP}
e.g
ltsp32
for client IP 192.168.67.32
``` 

`"ltsp/guest"` assigns each hostname a corresponding user, eg. `ltsp32` -> `guest32`.


### Creating guest accounts
By using the following script several users with the name `guest${ip}` will be created. The variable `ip` ranges from 20 to 250. This should be changed depending on the IP address range in `/etc/dnsmasq.d/ltsp-dnsmasq.conf` or how the router is configured.
To run the small script create a file, eg. `createguests.sh` paste the content 

```text
base="guest"
pass="guest"

mkdir /home/nfs

for ip in {20..250}; do
    user="${base}${ip}"
    adduser $user --disabled-password --gecos ""
    echo -e "$pass\n$pass\n" | sudo passwd $user
    mv "/home/${user}" /home/nfs/
    ln -s "nfs/${user}" "/home/${user}"
done
```

and make it executable:
```text
chmod +x createguests.sh
```

Afterwards run it as root:
```text
./createguests.sh
```

Now 230 users will be created with their `/home` folders in `/home/nfs` and the password `guest`.


### /home/nfs as NFS share
To serve only the guest accounts via NFS, the folder `/home/nfs` will be exported. This is done by adding the following line to `/etc/exports.d/ltsp-nfs.exports`.
```text
/home/nfs               *(rw,async,no_subtree_check,no_root_squash,insecure)
```


### Create the guest session
With a custom xsession we are able to modify the `/home` folder before starting the desktop environment. For a new session the file `/usr/share/xsessions/guest.desktop` with the content
```text
[Desktop Entry]
Name=Guest Session
Comment=Use this session to run a guest session as your environment
Exec=/etc/ltsp/setupsession.sh
Type=Application
DesktopNames=GUEST
```

is needed. Upon logging in `/etc/ltsp/setupsession.sh` will be executed.

Create the script `/etc/ltsp/setupsession.sh` with the content:
```text
#!/bin/bash
rm -R /home/${USER}; mkdir -p /home/${USER}; rsync -rtvp /etc/ltsp/template/ /home/${USER}; chown -R ${USER}:${USER} /home/${USER}
startxfce4
```

FIXME delete only if guest

This deletes the `/home` folder of the user logging in and creates a new one. Basic config files can reside in `/etc/ltsp/template/` to be copied to the new `/home` folder (eg. custom panel layouts with `.config` files).


By adding 
```text
LIGHTDM_CONF='user-session=guest'
```

to the `[clients]` section of `/etc/ltsp/ltsp.conf`, all clients will log in with the new session.
