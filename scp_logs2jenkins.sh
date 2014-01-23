#!/bin/bash

source jobrc

sshpass -p 'radware' scp ubuntu@$VM_IP:~/*log* .

#shpass -p 'radware' scp ubuntu@$VM_IP:~/tempest.log .


