#!/bin/bash -eux

# change cloud-init user name
sed -i 's/name: fedora/name: ec2-user/g' /etc/cloud/cloud.cfg

# use first grub option
grub2-set-default 0
grub2-mkconfig -o /boot/grub2/grub.cfg

# lock login user
passwd -l ec2-user

# delete cloud-init lock
rm -rf /var/lib/cloud/instance/sem/*
