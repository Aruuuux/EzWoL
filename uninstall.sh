#!/bin/bash

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

sed -i '/alias ezwol=/d' ~/.bashrc
echo -e "${GREEN} Alias 'ezwol' removed from ~/.bashrc ${NC}"

read -p "Do you want to delete your saved devices in ~/.ezwol ? (y/n): " clear_data
if [[ "$clear_data" == "y" ]]; then
    rm -rf "$HOME/.EzWoL"
    echo -e "${RED}[-] Configuration folder deleted ${NC}"
fi

echo -e "\n${YELLOW}Uninstall complete. Please run: source ~/.bashrc${NC}"
