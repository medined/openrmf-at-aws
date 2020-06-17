#!/bin/bash
IP_ADDRESS=$(cat inventory | tail -n 1)
xdg-open http://$IP_ADDRESS:8080 >/dev/null
