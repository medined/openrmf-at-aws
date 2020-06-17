#!/bin/bash

IP_ADDRESS=$(cat inventory | tail -n 1)
#IP_ADDRESS=18.234.255.255
ssh ec2-user@$IP_ADDRESS
