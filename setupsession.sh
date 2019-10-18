#!/bin/bash
rm -R /home/${USER}; mkdir -p /home/${USER}; rsync -rtvp /etc/ltsp/template/ /home/${USER}; chown -R ${USER}:${USER} /home/${USER}
startxfce4
