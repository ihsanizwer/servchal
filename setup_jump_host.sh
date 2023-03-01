#!/bin/bash
sudo sed -i 's/^nameserver.*/nameserver 168.63.129.16/g' /etc/resolv.conf
apt install ansible -y
