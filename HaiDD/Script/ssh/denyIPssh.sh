#!/bin/bash

sudo yum -y install tcp_wrappers

sudo apt-get install tcp_wrappers

echo "ALL: ALL" >> /etc/hosts.deny

echo "sshd: 10.10.35.197" >> /etc/hosts.allow

echo "sshd: 10.10.34.197" >> /etc/hosts.allow

echo "sshd: 103.101.160.130" >> /etc/hosts.allow

echo "sshd: 10.10.30.47" >> /etc/hosts.allow