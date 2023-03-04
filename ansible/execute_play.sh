#!/bin/bash
ANSIBLE_CONFIG=/home/azureuser/servchal/ansible/ansible.cfg
cd /home/azureuser/servchal/ansible
ansible-playbook playbook.yml --extra-vars ansible_ssh_private_key_file=app_serv_id_rsa --extra-vars ansible_user=azureuser --inventory-file inventory
        
