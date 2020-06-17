#!/bin/bash

IP_ADDRESS=$(cat inventory | tail -n 1)
ssh ec2-user@$IP_ADDRESS
