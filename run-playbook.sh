#!/bin/bash

ANSIBLE_PLAYBOOK=$(which ansible-playbook)

export ANSIBLE_HOST_KEY_CHECKING=False

python3 \
  $ANSIBLE_PLAYBOOK \
  --extra-vars "rmf_admin_password=PassworldRed123@@" \
  -i '3.231.159.157,' \
  -u ec2-user \
  playbook.openrmf.yml
