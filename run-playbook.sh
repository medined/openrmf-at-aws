#!/bin/bash

ANSIBLE_PLAYBOOK=$(which ansible-playbook)

export ANSIBLE_HOST_KEY_CHECKING=False

python3 \
  $ANSIBLE_PLAYBOOK \
  -i inventory \
  -u ec2-user \
  playbook.openrmf.yml
