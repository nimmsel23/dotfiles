#!/bin/bash
# SSH connection via local network from Termux
# Usage: ./termux-local-connect.sh

echo "Connecting via local network to alpha@192.168.178.27:22"
ssh alpha@192.168.178.27 -p 22
